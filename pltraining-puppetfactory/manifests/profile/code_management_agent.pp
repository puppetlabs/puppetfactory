class puppetfactory::profile::code_management_agent {
  include r10k
  include r10k::mcollective
  include puppet_enterprise::profile::mcollective::peadmin
}
