# frozen_string_literal: true

require 'rails_helper'

describe PostsController do
  let(:create_params) do
    {
      raw: 'hello',
      title: 'cool title',
      target_usernames: 'evil,trout',
      archetype: Archetype.private_message
    }
  end

  before do
    SiteSetting.bcc_enabled = true
  end

  it 'is not found when anonymous' do
    post '/posts/bcc.json', params: create_params
    expect(response.code).to eq('404')
  end

  it 'is not found when staff' do
    sign_in(Fabricate(:user))
    post '/posts/bcc.json', params: create_params
    expect(response.code).to eq('404')
  end

  context 'when logged in as staff' do
    fab!(:moderator) { Fabricate(:moderator) }

    before do
      sign_in(moderator)
    end

    it 'can report validation errors' do
      post '/posts/bcc.json', params: create_params.merge(raw: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaa')
      expect(response.code).to eq('422')
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it "returns an error if there aren't two usernames at least" do
      post '/posts/bcc.json', params: create_params.merge(target_usernames: 'test')
      expect(response.code).to eq('422')
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it "returns an error if it isn't a private message" do
      post '/posts/bcc.json', params: create_params.merge(archetype: Archetype.default)
      expect(response.code).to eq('422')
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'succeeds' do
      post '/posts/bcc.json', params: create_params
      expect(response.code).to eq('200')
    end
  end
end
