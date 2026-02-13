# PreferencesUI - User Preferences

PreferencesUI provides the user preferences and account
settings interface.

**Bundle:** `PreferencesUI.lso` (13 source files)


## Dependencies

- OGoFoundation
- LSFoundation


## Key Components

| Component | Purpose |
|-------------------------------|---------------------------|
| `LSWPreferencesViewer`        | View preferences          |
| `LSWPreferencesEditor`        | Edit preferences          |
| `SkyDisplayPreferences`       | Display settings          |
| `SkyDefaultEditField`         | Preference field editor   |
| `OGoDefaultEditField`         | Modern field editor       |
| `OGoDefaultEditFrame`         | Editor frame              |
| `OGoDefaultViewField`         | Read-only field           |


## Formatters

- `SimpleTextSepFormatter` - Text separator formatting
- `ArrayFormatter` - Array value formatting
- `BoolFormatter` - Boolean value formatting


# README

PreferencesUI
=============

Note: also contains the account editor and view! This is "LSWPreferencesViewer"
      and "LSWPreferencesEditor".

Todo
====

OGoDefaultEditField.m
- check whether isEditableDef and isEditable are supposed to be the same
  binding
