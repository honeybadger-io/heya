# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
