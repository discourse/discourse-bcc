# frozen_string_literal: true

require "rails_helper"

describe ::Jobs::BccPost do
  fab!(:sender) { Fabricate(:moderator) }
  fab!(:user0) { Fabricate(:user) }
  fab!(:user1) { Fabricate(:user) }
  let(:usernames) { [user0.username, user1.username] }

  let(:create_params) do
    HashWithIndifferentAccess.new(
      "raw" => "this is the content I want to send",
      "title" => "this is the title of the PM I want to send",
      "archetype" => Archetype.private_message
    )
  end

  it "does nothing when disabled" do
    topic_count = Topic.count
    ::Jobs::BccPost.new.execute(user_id: sender.id, create_params: create_params)
    expect(Topic.count).to eq(topic_count)
  end

  context "when enabled" do
    before do
      SiteSetting.bcc_enabled = true
      Group.refresh_automatic_groups!
    end

    it "will send messages to each user" do
      topic_count = Topic.count
      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params,
        targets_key: 'target_usernames',
        targets: [user0.username, user1.username]
      )
      expect(Topic.count).to eq(topic_count + 2)
    end

    it "does not crash when user's name is empty" do
      user0.update!(name: nil)
      expect {
        ::Jobs::BccPost.new.execute(
          user_id: sender.id,
          create_params: create_params,
          targets_key: 'target_usernames',
          targets: usernames)
      }.not_to raise_error
    end

    it 'works when mixing emails and usernames' do
      SiteSetting.enable_staged_users = true
      topic_count = Topic.count

      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params,
        targets_key: 'target_usernames',
        targets: [user0.username, user1.username])

      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params,
        targets_key: 'target_emails',
        targets: ['test@test.com']
      )

      expect(Topic.count).to eq(topic_count + 3)
    end

    it 'works when only using emails' do
      SiteSetting.enable_staged_users = true
      topic_count = Topic.count

      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params,
        targets_key: 'target_emails',
        targets: ['test@test.com', 'test2@test.com']
      )

      expect(Topic.count).to eq(topic_count + 2)
    end

    it 'works with standard personalization' do
      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params.merge(
          "raw": "this is the content I want to send to %{username}"
        ),
        targets_key: 'target_usernames',
        targets: [user1.username])
      post = Post.find_by(raw: "this is the content I want to send to #{user1.username}")

      expect(post).to_not be_nil
    end

    it 'works with mention personalization' do
      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params.merge(
          "raw": "this is the content I want to send to %{@username}"
        ),
        targets_key: 'target_usernames',
        targets: [user1.username]
      )
      post = Post.find_by(raw: "this is the content I want to send to @#{user1.username}")

      expect(post).to_not be_nil
    end

    it 'works with name personalization' do
      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params.merge(
          "raw": "this is the content I want to send to %{name}"
        ),
        targets_key: 'target_usernames',
        targets: [user1.username]
      )
      post = Post.find_by(raw: "this is the content I want to send to #{user1.name}")

      expect(post).to_not be_nil
    end

  end
end
