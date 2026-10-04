# Asset provenance and publication status

On 2026-10-04, the user confirmed that the retained custom PetTrack artwork is
team-authored and approved for public redistribution with the project under the
root [MIT License](LICENSE). This confirmation supplies the rights information
missing from the initial asset review; no individual creator is asserted.
Editing metadata or launcher-icon generation alone does not establish authorship.

| Asset or group | Evidence and classification | Treatment |
| --- | --- | --- |
| `assets/icon/app_icon.png` | Team-authored PetTrack project artwork; paw/cat/dog branding with GIMP editing metadata. | Approved for public redistribution; historical launcher source. |
| `assets/images/icon_bold.svg` | Team-authored PetTrack project artwork; matching paw branding edited in Inkscape. | Approved for public redistribution; used by the app bar. |
| `assets/images/empty_bowl.svg`, `full_bowl.svg` | Team-authored PetTrack project artwork; feeding illustrations edited in Inkscape. | Approved for public redistribution; used by the feeding widget. |
| `assets/images/gat.png`, `gos.png` | Team-authored PetTrack project artwork; cat/dog silhouette placeholders. | Approved for public redistribution; historical species placeholders. |
| Android `mipmap-*/ic_launcher.png` and iOS `AppIcon.appiconset/*.png` | Generated size variants of the confirmed team-authored PetTrack branding. | Approved for public redistribution with their cleared source artwork. |
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
the working tree does **not** remove historical Git copies. The user explicitly
declined history rewriting and accepted that earlier media may become accessible
when the repository is published.

`gat` and `gos` correspond to the historical Firestore species codes for cat and dog.
Those identifiers are preserved to avoid a schema migration. Species placeholders
are used when a pet has no uploaded photo. Unknown or absent species can produce
a nonexistent fallback path; that behavior has not been redesigned in this pass.

The artwork confirmation applies to the retained custom assets and Android/iOS
launcher derivatives. It does not clear the three excluded media files or replace
the separate upstream terms for Flutter/template assets.
