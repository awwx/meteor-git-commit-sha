Package.describe({
  summary: "adds the git commit sha to the Meteor runtime config"
});

Package.on_use(function (api) {
  api.use('when', 'server');
  api.add_files(['git-commit-sha.js'], 'server');
});
