# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Create `bcc:` optional parameter for steps; use case is quality control

## [0.5.2] - 2021-08-11
### Fixed
- Fix typo in initializer (#139, @800a7b32)

## [0.5.1] - 2021-07-13
### Fixed
- Fix compatibility with Rails 6.1.4 (introduced by [this change](https://github.com/rails/rails/commit/99049262d37fedcd25af91231423103b0d218694#diff-79b53b2602bf702bdd8ce677e096be6a6923a54236e17237c16068a510078683) to `build_arel`) (#137, @retsef)

## [0.5.0] - 2021-06-17
### Added
- Create `@campaign_name` instance var accessible in email templates (#135)

## [0.4.0] - 2021-02-04
### Changed
- Added the `step_gid` column to the `heya_campaign_memberships` table. This
  change requires running a migration to upgrade. [Instructions](./UPGRADING.md#004). (#83)

## [0.3.0] - 2020-06-02
### Added
- Support I18n translations for email subjects (#81)

## [0.2.1] - 2020-04-23
### Fixed
- Update the install and campaign generators.

## [0.2.0] - 2020-04-14
### Added
- Added licensing.
- Added `rescue_from` (rescuable) in campaigns.

## [0.1.0] - 2020-03-19
### Added
- Initial release. 👋
