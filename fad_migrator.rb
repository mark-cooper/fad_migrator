#!/usr/bin/env ruby

require 'archivesspace/client'
require 'http'
require 'yaml'

# ARCHIVESSPACE_CLIENT_TEMPLATES_PATH=$(pwd)/templates bundle exec ruby fad_migrator.rb

FM_CFG   = YAML.load(File.read('./config.yml'))
REPO_CFG = YAML.load(HTTP.get(FM_CFG['repo_cfg_url']).body)
config = ArchivesSpace::Configuration.new(
  {
    base_uri: FM_CFG['base_uri'],
    username: FM_CFG['username'],
    password: FM_CFG['password'],
    verify_ssl: true
  }
)
client = ArchivesSpace::Client.new(config).login

REPO_CFG.each do |repo_code, cfg|
  repo_data = {
    repo_code: repo_code,
    name: cfg['name'],
    country: 'US',
    image_url: cfg['thumbnail_url'],
    agent_contact_name: cfg['name'],
    agent_contact_address_1: cfg['building'],
    agent_contact_address_2: cfg['address1'],
    agent_contact_address_3: cfg['address2'],
    agent_contact_city: cfg['city'],
    agent_contact_state: cfg['state'],
    agent_contact_country: 'US',
    agent_contact_post_code: cfg['zip'],
    agent_contact_telephone: cfg['phone'],
  }
  json = ArchivesSpace::Template.process(:repository, repo_data)
  begin
    repo = client.repositories.find { |r| r['repo_code'] == repo_code }
    if repo
      puts({ status: "Found", uri: repo["uri"], repo_code: repo["repo_code"] })
    else
      puts client.post('/repositories/with_agent', json).parsed
    end
  rescue ArchivesSpace::RequestError => e
    puts e.message
  end
end