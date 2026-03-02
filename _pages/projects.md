---
layout: page
title: Projects
permalink: /projects/
---

{% for project in site.data.projects %}
### {{ project.title }}

{{ project.description }}

{% if project.post_url != "" %}[Read the write-up]({{ project.post_url }}){% endif %}
{% if project.github_url != "" %} · [View on GitHub]({{ project.github_url }}){% endif %}

---
{% endfor %}
