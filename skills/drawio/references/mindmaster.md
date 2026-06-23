# MindMaster / EdrawMind Reference

Use MindMaster for mind maps when the user asks for MindMaster, EdrawMind, `.emmx`, or a native editable mind-map file. Use draw.io for general diagrams, flowcharts, architecture diagrams, and wireframes.

## Global command

This machine exposes MindMaster through:

```powershell
mindmaster [path-to-file]
```

The command is a wrapper at `C:\Users\tyk\bin\mindmaster.cmd`, which is already on PATH. It finds `MindMaster.exe` under `%ProgramFiles%\Edrawsoft\MindMaster*`.

## Generate a simple `.emmx`

Use the bundled script for a first-level mind map:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\skills\drawio\scripts\new-mindmaster-map.ps1" `
  -Title "Project Plan" `
  -Branch "Goal","Scope","Timeline","Risks" `
  -Output "$env:USERPROFILE\Desktop\project-plan.emmx" `
  -Open
```

The script writes a native MindMaster `.emmx` file and optionally opens it with `mindmaster`.

## `.emmx` structure

`.emmx` is a ZIP container. The minimal native structure used here is:

```text
document.xml
page/page.xml
rels/page_rels.xml
theme.xml
thumbnail.png
```

`page/page.xml` stores `Shape` nodes:

- `MainIdea`: center topic. Its `LevelData/SubLevel` lists child topic IDs separated by `;`.
- `MainTopic`: first-level branch. Its `LevelData/Super` points to the center topic, and `ToSuper` points to the connector shape.
- `MMConnector`: visible edge from the center topic to a branch.

Keep XML well-formed and escape user text before writing it into `tp` text nodes.
