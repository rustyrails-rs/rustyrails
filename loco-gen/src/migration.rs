use crate::{
    infer, model::get_columns_and_references, render_template, AppInfo, GenerateResults, Result,
};
use chrono::Utc;
use rrgen::RRgen;
use serde_json::json;
use std::path::Path;

/// skipping some fields from the generated models.
/// For example, the `created_at` and `updated_at` fields are automatically
/// generated by the Loco app and should be given
pub const IGNORE_FIELDS: &[&str] = &["created_at", "updated_at", "create_at", "update_at"];

pub fn generate(
    rrgen: &RRgen,
    name: &str,
    fields: &[(String, String)],
    appinfo: &AppInfo,
) -> Result<GenerateResults> {
    let pkg_name: &str = &appinfo.app_name;
    let ts = Utc::now();

    let res = infer::guess_migration_type(name);
    match res {
        // NOTE: re-uses the 'new model' migration template!
        infer::MigrationType::CreateTable { table } => {
            let (columns, references) = get_columns_and_references(fields)?;
            let vars = json!({"name": table, "ts": ts, "pkg_name": pkg_name, "is_link": false, "columns": columns, "references": references});
            render_template(rrgen, Path::new("model/model.t"), &vars)
        }
        infer::MigrationType::AddColumns { table } => {
            let (columns, references) = get_columns_and_references(fields)?;
            let vars = json!({"name": name, "table": table, "ts": ts, "pkg_name": pkg_name, "is_link": false, "columns": columns, "references": references});
            render_template(rrgen, Path::new("migration/add_columns.t"), &vars)
        }
        infer::MigrationType::RemoveColumns { table } => {
            let (columns, _references) = get_columns_and_references(fields)?;
            let vars = json!({"name": name, "table": table, "ts": ts, "pkg_name": pkg_name, "columns": columns});
            render_template(rrgen, Path::new("migration/remove_columns.t"), &vars)
        }
        infer::MigrationType::AddReference { table } => {
            let (columns, references) = get_columns_and_references(fields)?;
            let vars = json!({"name": name, "table": table, "ts": ts, "pkg_name": pkg_name, "columns": columns, "references": references});
            render_template(rrgen, Path::new("migration/add_references.t"), &vars)
        }
        infer::MigrationType::CreateJoinTable { table_a, table_b } => {
            let mut tables = [table_a.clone(), table_b.clone()];
            tables.sort();
            let table = tables.join("_");
            let (columns, references) = get_columns_and_references(&[
                (table_a, "references".to_string()),
                (table_b, "references".to_string()),
            ])?;
            let vars = json!({"name": name, "table": table, "ts": ts, "pkg_name": pkg_name, "columns": columns, "references": references});
            render_template(rrgen, Path::new("migration/join_table.t"), &vars)
        }
        infer::MigrationType::Empty => {
            let vars = json!({"name": name, "ts": ts, "pkg_name": pkg_name});
            render_template(rrgen, Path::new("migration/empty.t"), &vars)
        }
    }
}
