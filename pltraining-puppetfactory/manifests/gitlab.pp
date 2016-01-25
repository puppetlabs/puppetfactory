class puppetfactory::gitlab {
  docker::run {'gitlab':
    image => 'gitlab/gitlab-ce',
    ports => ['8080:80'],
  }
}
