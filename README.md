# deprecated-catalog-content

#### (Facilitating initial backfill of deprecated catalog content from operator authors)

## Background and Overview
With OCP 4.15 operator framework has introduced a new deprecation marker for File-Based Catalogs (FBC).  This marker is similar in name to those used by legacy (SQLite) catalog formats, but with a different intent.

In legacy catalogs, OLM supported two CSV properties which influenced upgrade reconciliation:
- `olm.deprecated`, meaning "omit from reconciliation"
- `olm.substitutesFor`, meaning "replaces a bundle with another"

Both of these properties were attempting to overcome limitations of the legacy catalog approach, whether it was that the catalog required no dangling bundle references but needed an 'out of bounds' marker on some versions (olm.deprecated), or that the principle of bundle immutability prevented the easy 'republication' of a bundle version in order to surpass a mistake, vulnerability, etc. (olm.substitutesFor).

With FBC catalogs, operator authors have much greater flexibility to express bundle upgrade graphs, but until this feature, the analog to the old `olm.deprecated` property was to omit the bundle version from the upgrade graph entirely.  Authors asked for more nuance than a metaphoric cliff that bundle versions fall off of, and the new schema is an attempt to capture that nuance.

## GOAL
### This is fine for all future bundle deployments and graph updates, but what about all the existing catalog content?
**This repo is a request to operator author operators to start providing deprecation metadata about their operators and their upgrade graphs now, without requiring a bundle-republish or graph update, to be used in the OCP4.15 (and later) releases.**

We ask that operator authors open a PR against this repository with the deprecations relevant to them.
<hr>

## Schema and Guardrails
The general format of an `olm.deprecations` schema is
```yaml
schema: olm.deprecations
package: <MANDATORY>package-name # this must be unique across the catalog
entries: # at least one of below reference types
- reference:
    schema: olm.bundle # bundle version scope
    name: <MANDATORY>bundle-version-name
  message: <MANDATORY>descriptive message to catalog users about the specified bundle (e.g. suggested replacements)
- reference:
    schema: olm.package
  <MANDATORY>no name, since it is already specified and unique per-package
  message: <MANDATORY>descriptive message to catalog users about the specified package (e.g. suggested replacements)
- reference:
    schema: olm.channel
    name: <MANDATORY>channel-name
  message: <MANDATORY>descriptive message to catalog users about the specified channel (e.g. suggested replacements)
```
The top-level `package` name is required.  This should be the same as the package name used in the catalog.  There should be at most one `olm.deprecations` schema for a package.

There are discrete `entries` types for package, channel, or bundle scopes.  Each has their own requirements which are enforced by `opm validate`.  Each entry is composed of a mandatory `reference` field to indicate the deprecation scope and a mandatory `message` field which is represented as an opaque text blob.
- `olm.package`: represents the entire package.  There must not be an associated `name`.
- `olm.channel`: represents one channel.  `name` (channel name) is mandatory.
- `olm.bundle`:  represents one bundle version.  `name` (bundle version name) is mandatory.

## Example
The below example demonstrates an instance of the `olm.deprecations` schema against the `kiali` package which enumerates a deprecation against each possible scope:
```yaml
schema: olm.deprecations
package: kiali
entries:
  - reference:
      name: kiali-operator.v1.68.0
      schema: olm.bundle
    message: |
        kiali-operator.v1.68.0 is deprecated. Uninstall and install kiali-operator.v1.72.0 for support.
  - reference:
      schema: olm.package
    message: |
        package kiali is end of life.  Please use 'kiali-new' package for support.
  - reference:
      name: alpha
      schema: olm.channel
    message: |
      channel alpha is no longer supported.  Please switch to channel 'stable'.
```
