export default {
  extends: ['@commitlint/config-conventional'],
  defaultIgnores: true,
  ignores: [
    // Ignore dependabot commit messages.
    (commit) => (
      commit.startsWith('chore(deps):')
      || commit.startsWith('build(deps):')
    )
  ]
}
