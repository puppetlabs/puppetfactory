class puppetfactory::gitlab {
  docker::run {'gitlab':
    image => 'gitlab/gitlab-ce',
    ports => ['8888:80','2222:22'],
  }
}
