{% set file_name = name |  snake_case -%}
{% set module_name = file_name | pascal_case -%}
to: assets/views/{{file_name}}/edit.html
skip_exists: true
message: "{{file_name}} edit view was added successfully."
---
{% raw %}{% extends "base.html" %}{% endraw %}

{% raw %}{% block title %}{% endraw %}
Edit {{name}}: {% raw %}{{ item.id }}{% endraw %}
{% raw %}{% endblock title %}{% endraw %}

{% raw %}{% block content %}{% endraw %}
<h1>Edit {{name}}: {% raw %}{{ item.id }}{% endraw %}</h1>
<div class="mb-10">
    <form hx-put="/{{name | plural}}/{% raw %}{{ item.id }}{% endraw %}" hx-ext="submitjson" hx-target="#success-message">
    <div class="mb-5">
    {% for column in columns -%}
        <div>
        <label>{{column.0}}</label>
        <br />
        {% if column.2 == "text" -%}
        <textarea id="{{column.0}}" name="{{column.0}}" type="text">{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}</textarea>
        {% elif column.2 == "string" -%}
        <input id="{{column.0}}" name="{{column.0}}" type="text" value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}"></input>
        {% elif column.2 == "string!" or column.2 == "string^" -%}
        <input id="{{column.0}}" name="{{column.0}}" type="text" value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}" required></input>
        {% elif column.2 == "int" or column.2 == "int!" or column.2 == "int^"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="number" required value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}"></input>
        {% elif column.2 == "bool"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="checkbox" value="true" {% raw %}{% if item.{% endraw %}{{column.0}}{% raw %} %}checked{%endif %}{% endraw %}></input>
        {% elif column.2 == "bool!"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="checkbox" value="true" {% raw %}{% if item.{% endraw %}{{column.0}}{% raw %} %}checked{%endif %}{% endraw %} required></input>
        {% elif column.2 == "ts"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="text" value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}"></input>
        {% elif column.2 == "ts!"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="text" value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}" required></input>
        {% elif column.2 == "uuid"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="text" value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}"></input>
        {% elif column.2 == "uuid!"-%}
        <input id="{{column.0}}" name="{{column.0}}" type="text" value="{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}" required></input>
        {% elif column.2 == "json" or column.2 == "jsonb" -%}
        <textarea id="{{column.0}}" name="{{column.0}}" type="text">{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}</textarea>
        {% elif column.2 == "json!" or column.2 == "jsonb!" -%}
        <textarea id="{{column.0}}" name="{{column.0}}" type="text" required>{% raw %}{{item.{% endraw %}{{column.0}}{% raw %}}}{% endraw %}</textarea>
        {% elif column.2 == "array!" or column.2 == "array^" -%}
         <div id="{{column.0}}-inputs"> 
               {% raw %}{%{% endraw %} for data in item.{{column.0}} {% raw %}-%}{% endraw %}
                    <input name="{{column.0}}[]" value="{% raw %}{{data}}{% endraw %}" class="mb-2" type="text" required />
                 {% raw %}{% endfor -%}{% endraw %}
          </div>
          <button type="button" class="text-xs py-1 px-3 rounded-lg bg-gray-900 text-white add-more"
                    data-group="{{column.0}}">Add More</button>
        {% elif column.2 == "array"  -%}
         <div id="{{column.0}}-inputs">
              {% raw %}{%{% endraw %} for data in item.{{column.0}} {% raw %}-%}{% endraw %}
                    <input name="{{column.0}}[]" value="{% raw %}{{data}}{% endraw %}" class="mb-2" type="text" />
                {% raw %}{% endfor -%}{% endraw %}
         </div>
          <button type="button" class="text-xs py-1 px-3 rounded-lg bg-gray-900 text-white add-more"
                    data-group="{{column.0}}">Add More</button>
        {% endif -%} 
        </div>
    {% endfor -%}
    </div>
    <div>
        <div class="mt-5">
            <button class=" text-xs py-3 px-6 rounded-lg bg-gray-900 text-white" type="submit">Submit</button>
            <button class="text-xs py-3 px-6 rounded-lg bg-red-600 text-white"
                        onclick="confirmDelete(event)">Delete</button>
        </div>
    </div>
</form>
<div id="success-message" class="mt-4"></div>
<br />
<a href="/{{name | plural}}">Back to {{name}}</a>
</div>
{% raw %}{% endblock content %}{% endraw %}

{% raw %}{% block js %}{% endraw %}
<script>
    htmx.defineExtension('submitjson', {
        onEvent: function (name, evt) {
            if (name === "htmx:configRequest") {
                evt.detail.headers['Content-Type'] = "application/json"
            }
        },
        encodeParameters: function (xhr, parameters, elt) {
            const json = {};
            // Handle individual field inputs
            for (const [key, value] of Object.entries(parameters)) {
                const inputType = elt.querySelector(`[name="${key}"]`).type;
                if (inputType === 'number') {
                    json[key] = parseFloat(value);
                } else if (inputType === 'checkbox') {
                    json[key] = elt.querySelector(`[name="${key}"]`).checked;
                } else {
                    json[key] = value;
                }
            }

            // Handle array inputs dynamically based on the name
            elt.querySelectorAll('[name]').forEach(input => {
                if (input.name.endsWith('[]')) {
                    const group = input.name.split('[')[0]; // Extract group name

                    if (!json[group]) {
                        json[group] = [];
                    }
                    json[group].push(input.value);
                }
            });

            return JSON.stringify(json);
        }
    })
    function confirmDelete(event) {
        event.preventDefault();
        if (confirm("Are you sure you want to delete this item?")) {
            var xhr = new XMLHttpRequest();
            xhr.open("DELETE", "/{{name | plural}}/{% raw %}{{ item.id }}{% endraw %}", true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState == 4 && xhr.status == 200) {
                    window.location.href = "/{{name | plural}}";
                }
            };
            xhr.send();
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.querySelectorAll('.add-more').forEach(button => {
            button.addEventListener('click', function () {
                const group = this.getAttribute('data-group');
                const container = document.getElementById(`${group}-inputs`);
                const newInput = document.createElement('input');
                newInput.type = 'text';
                newInput.name = `${group}[]`;
                newInput.placeholder = `Enter another ${group} value`;
                container.appendChild(newInput);
            });
        });
    });
</script>
{% raw %}{% endblock js %}{% endraw %}