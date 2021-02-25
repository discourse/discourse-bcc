# frozen_string_literal: true

describe ::Jobs::BccPost do
  fab!(:sender) { Fabricate(:moderator) }
  fab!(:user0) { Fabricate(:user) }
  fab!(:user1) { Fabricate(:user) }

  let(:create_params) do
    HashWithIndifferentAccess.new(
      "raw" => "this is the content I want to send",
      "title" => "this is the title of the PM I want to send",
      "archetype" => Archetype.private_message,
      target_usernames: "#{user0.username},#{user1.username}"
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
    end

    it "will send messages to each user" do
      topic_count = Topic.count
      ::Jobs::BccPost.new.execute(user_id: sender.id, create_params: create_params)
      expect(Topic.count).to eq(topic_count + 2)
    end

    it 'works when mixing emails and usernames' do
      SiteSetting.enable_staged_users = true
      topic_count = Topic.count

      ::Jobs::BccPost.new.execute(user_id: sender.id, create_params: create_params.merge(target_emails: 'test@test.com'))

      expect(Topic.count).to eq(topic_count + 3)
    end

    it 'works when only using emails' do
      SiteSetting.enable_staged_users = true
      topic_count = Topic.count

      ::Jobs::BccPost.new.execute(
        user_id: sender.id,
        create_params: create_params.merge(
          target_usernames: nil,
          target_emails: 'test@test.com,test2@test.com'
        )
      )

      expect(Topic.count).to eq(topic_count + 2)
    end
    
    it 'works with personalization' do
      edited_params = create_params
      edited[:raw] += " to {username}"
      ::Jobs::BccPost.new.execute(user_id: sender.id, create_params: edited)
      
      expect(Post.find_by({topic_id: Topic.count-1}).raw[
        -user1.username.length, user1.username.length
        ]).to eq(user1.username)
    end  
      
  end
end
