# Themes - Web UI Themes

Themes provides CSS stylesheets, images, JavaScript,
and localization resources for the OGo web interface.
Multiple theme variants are available in different
color schemes and languages.


## Theme Variants

| Theme | Description |
|---------------------------|-------------------------------|
| `English.lproj`           | Default English theme         |
| `German.lproj`            | German localization           |
| `Danish.lproj`            | Danish localization           |
| `Italian.lproj`           | Italian localization          |
| `Spanish.lproj`           | Spanish localization          |
| `Polish.lproj`            | Polish localization           |
| `Portuguese (BR).lproj`   | Brazilian Portuguese          |
| `English_blue.lproj`      | Blue color scheme             |
| `German_blue.lproj`       | German blue variant           |
| `English_kde.lproj`       | KDE-themed variant            |
| `English_OOo.lproj`       | OpenOffice-themed variant     |
| `German_OOo.lproj`        | German OpenOffice variant     |
| `English_orange.lproj`    | Orange color scheme           |
| `German_orange.lproj`     | German orange variant         |
| `Danish_orange.lproj`     | Danish orange variant         |


## Theme Contents

Each theme directory contains:

- **CSS** - `OGo.css` main stylesheet plus
  theme-specific overrides
- **JavaScript** - `menu.js` (navigation),
  `LSWAppointmentEditor.js` (calendar editor)
- **Icons** - Application icons, appointment type
  icons, status indicators, navigation graphics
- **Images** - Backgrounds, container graphics


## Installation

Themes are installed to the `WebServerResources`
directory during build. Users can select their preferred
theme via user preferences.
