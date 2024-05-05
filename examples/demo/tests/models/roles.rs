use blo::{
    app::App,
    models::{roles, sea_orm_active_enums, users, users::RegisterParams, users_roles},
};
use loco_rs::{db::truncate_table, prelude::*, testing};
use sea_orm::DatabaseConnection;
use serial_test::serial;

async fn truncate_this(db: &DatabaseConnection) -> Result<(), ModelError> {
    truncate_table(db, roles::Entity).await?;
    truncate_table(db, users::Entity).await?;
    truncate_table(db, users_roles::Entity).await?;
    Ok(()).map_err(|_: ModelError| ModelError::EntityNotFound)
}

macro_rules! configure_insta {
    ($($expr:expr),*) => {
        let mut settings = insta::Settings::clone_current();
        settings.set_prepend_module_to_snapshot(false);
        settings.set_snapshot_suffix("roles");
        let _guard = settings.bind_to_scope();
    };
}

#[tokio::test]
#[serial]
async fn can_add_user_to_admin() {
    configure_insta!();

    let boot = testing::boot_test::<App>().await.unwrap();
    testing::seed::<App>(&boot.app_context.db).await.unwrap();
    let _t = truncate_this(&boot.app_context.db).await;
    let new_user: Result<users::Model, ModelError> = users::Model::create_with_password(
        &boot.app_context.db,
        &RegisterParams {
            email: "user1@example.com".to_string(),
            password: "1234".to_string(),
            name: "framework".to_string(),
        },
    )
    .await;
    let new_user = new_user.unwrap();
    let role = roles::Model::add_user_to_admin_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::Admin);
}

#[tokio::test]
#[serial]
async fn can_add_user_to_user() {
    configure_insta!();

    let boot = testing::boot_test::<App>().await.unwrap();
    testing::seed::<App>(&boot.app_context.db).await.unwrap();
    let _t = truncate_this(&boot.app_context.db).await;
    let new_user: Result<users::Model, ModelError> = users::Model::create_with_password(
        &boot.app_context.db,
        &RegisterParams {
            email: "user1@example.com".to_string(),
            password: "1234".to_string(),
            name: "framework".to_string(),
        },
    )
    .await;
    let new_user = new_user.unwrap();
    let role = roles::Model::add_user_to_user_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::User);
}

#[tokio::test]
#[serial]
async fn can_convert_between_user_and_admin() {
    configure_insta!();

    let boot = testing::boot_test::<App>().await.unwrap();
    testing::seed::<App>(&boot.app_context.db).await.unwrap();
    let _t = truncate_this(&boot.app_context.db).await;
    let new_user: Result<users::Model, ModelError> = users::Model::create_with_password(
        &boot.app_context.db,
        &RegisterParams {
            email: "user1@example.com".to_string(),
            password: "1234".to_string(),
            name: "framework".to_string(),
        },
    )
    .await;
    let new_user = new_user.unwrap();
    let role = roles::Model::add_user_to_user_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::User);
    let role = roles::Model::add_user_to_admin_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::Admin);
    let role = roles::Model::add_user_to_user_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::User);
}

#[tokio::test]
#[serial]
async fn can_find_user_roles() {
    configure_insta!();

    let boot = testing::boot_test::<App>().await.unwrap();
    testing::seed::<App>(&boot.app_context.db).await.unwrap();
    let _t = truncate_this(&boot.app_context.db).await;
    let new_user: Result<users::Model, ModelError> = users::Model::create_with_password(
        &boot.app_context.db,
        &RegisterParams {
            email: "user1@example.com".to_string(),
            password: "1234".to_string(),
            name: "framework".to_string(),
        },
    )
    .await;
    let new_user = new_user.unwrap();
    let role = roles::Model::add_user_to_user_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::User);

    let role = roles::Model::find_by_user(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::User);

    let role = roles::Model::add_user_to_admin_role(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::Admin);

    let role = roles::Model::find_by_user(&boot.app_context.db, &new_user)
        .await
        .unwrap();
    assert_eq!(role.name, sea_orm_active_enums::RolesName::Admin);
}

#[tokio::test]
#[serial]
async fn cannot_find_user_before_conversation() {
    configure_insta!();

    let boot = testing::boot_test::<App>().await.unwrap();
    testing::seed::<App>(&boot.app_context.db).await.unwrap();
    let _t = truncate_this(&boot.app_context.db).await;
    let new_user: Result<users::Model, ModelError> = users::Model::create_with_password(
        &boot.app_context.db,
        &RegisterParams {
            email: "user1@example.com".to_string(),
            password: "1234".to_string(),
            name: "framework".to_string(),
        },
    )
    .await;
    let new_user = new_user.unwrap();
    let role = roles::Model::find_by_user(&boot.app_context.db, &new_user).await;
    assert!(role.is_err());
}
