# Investigations

## Hetzner fresh deploy: stale `external-dns` Application field survived

Date: 2026-03-25

Observed on a fresh Hetzner cluster after bootstrap:

- Argo CD child app `external-dns` was `Synced` but `Progressing`
- `external-dns` pod crashed with `unknown long flag '--txt-owner-id-old'`
- the live `Application/external-dns` object still contained `spec.sources[0].helm.valuesObject.extraArgs.txt-owner-id-old`
- that field was not present in the repo working tree or on `origin/feat/review-fixes`

Manual recovery used on the cluster:

- removed `/spec/sources/0/helm/valuesObject/extraArgs` from `Application/external-dns`
- forced Argo CD hard refresh
- `external-dns` reconciled and became healthy

Open questions:

- why did the stale `extraArgs` field remain on the live child `Application`
- whether this was caused by previous branch history, field ownership, bootstrap ordering, or Argo CD reconciliation behavior
- whether a repo-level fix is needed, or whether this was one-off live drift

Do not assume this is cloud-wide. It was only observed on the Hetzner cluster created on 2026-03-25.
