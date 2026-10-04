# Asset provenance and publication status

This inventory records historical presentation assets, not a grant of reuse rights.
The repository contains no original asset attribution or permission record. Editing
an image in GIMP/Inkscape or resizing it with launcher-icon tooling does not establish
authorship or permission for underlying artwork.

| Asset or group | Evidence and classification | Treatment |
| --- | --- | --- |
| `assets/icon/app_icon.png` | PetTrack-specific paw/cat/dog branding; GIMP editing metadata. Underlying artwork authorship and rights unconfirmed. | Retained as the historical launcher source, pending confirmation before publication. |
| `assets/images/icon_bold.svg` | Matching paw branding, edited in Inkscape. Underlying artwork rights unconfirmed. | Retained because the app bar uses it; confirmation required before publication. |
| `assets/images/empty_bowl.svg`, `full_bowl.svg` | Feeding illustrations edited in Inkscape, with no creator/license statement. | Retained because the feeding widget uses them; confirmation required before publication. |
| `assets/images/gat.png`, `gos.png` | Cat/dog silhouette placeholders; no attribution metadata or identified original source. | Retained as historical species placeholders; confirmation required before publication. |
| Android `mipmap-*/ic_launcher.png` and iOS `AppIcon.appiconset/*.png` | Generated size variants of the PetTrack branding. | Same unresolved underlying rights as `app_icon.png`; generation does not clear them. |
| macOS `AppIcon.appiconset/*.png`, web favicon/icons, Windows `app_icon.ico` | Default Flutter template artwork, distinct from custom PetTrack icons. | Retained as framework/tooling assets, not claimed as team artwork. |
| iOS `LaunchImage.imageset/*.png` | Default template launch placeholders. | Retained as framework boilerplate. |
| `assets/images/logo.png` | PetTrack wordmark composite with GIMP metadata but no underlying-artwork attribution. | Excluded; the README uses a text title. |
| `assets/images/example.jpg` | Dog photograph with no photographer/source/reuse record. No direct code reference found. | Excluded. |
| `assets/images/screenshots.png` | Historical PetTrack UI composite with pet records/photos and a map. Record ownership, photograph permissions, map attribution and mockup rights unestablished. | Excluded rather than published or silently edited. No new screenshots were created. |

Framework/template identification and the upstream notice are recorded in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Exact byte comparisons confirmed
the web favicon/192/512 icons and iOS launch placeholders; the other default icons
were identified by template role/artwork, without an exact cache-revision match.

Excluded originals are preserved privately outside the repository. Exclusion from
the working tree does **not** remove historical Git copies.

`gat` and `gos` correspond to the historical Firestore species codes for cat and dog.
Those identifiers are preserved to avoid a schema migration. Species placeholders
are used when a pet has no uploaded photo. Unknown or absent species can produce
a nonexistent fallback path; that behavior has not been redesigned in this pass.

Before changing visibility, confirm team authorship/permission for retained custom
artwork, or separately authorize replacing/excluding it and all launcher derivatives.
Do not assign an invented source or license.
