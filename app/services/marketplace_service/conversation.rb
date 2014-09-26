module MarketplaceService
  module Conversation
    ConversationModel = ::Conversation
    ParticipationModel = ::Participation
    PersonModel = ::Person
    PersonEntity = MarketplaceService::Person::Entity

    module Entity
      Conversation = EntityUtils.define_entity(
        :id,
        :participants,
        :messages,
        :transaction,
        :listing,
        :last_message_at
      )

      ConversationParticipant = EntityUtils.define_entity(
        :person,
        :is_read,
        :is_starter,
      )

      Message = EntityUtils.define_entity(
        :sender,
        :content,
        :created_at
      )

      TransactionEntity = MarketplaceService::Transaction::Entity
      Listing = TransactionEntity::Listing
      Transaction = TransactionEntity::Transaction
      Transition = TransactionEntity::Transition
      Testimonial = TransactionEntity::Testimonial

      module_function

      def participant_by_id(conversation, person_id)
        conversation[:participants]
          .select { |participant| participant[:person][:id] == person_id }
          .map { |participant| participant[:person] }
          .first
      end

      def other_by_id(conversation, person_id)
        conversation[:participants]
          .reject { |participant| participant[:person][:id] == person_id }
          .map { |participant| participant[:person] }
          .first
      end

      def conversation(conversation_model)
        Conversation[{
          id: conversation_model.id,
          participants: participations(conversation_model.participations),
          listing: conversation_model.listing,
          messages: messages(conversation_model.messages),
          last_message_at: conversation_model.last_message_at
        }]
      end

      def participations(participation_models)
        participation_models.map { |participation_model| participation(participation_model) }
      end

      def participation(participation_model)
        ConversationParticipant[{
          person: PersonEntity.person(participation_model.person),
          is_read: participation_model.is_read,
          is_starter: participation_model.is_starter
        }]
      end

      def messages(message_models)
        message_models
          .reject { |msg|
            # We should be able to get rid of this soon. Previously, blank content meant that the message was abount a
            # transaction transition. However, currently the transitions are separated from messages
            msg.content.blank?
          }
          .map { |msg| message(msg) }
      end

      def message(message_model)
        Message[{
          sender: PersonEntity.person(message_model.sender),
          content: message_model.content,
          created_at: message_model.created_at
        }]
      end
    end

    module Command
      module_function

      def mark_as_read(conversation_id, person_id)
        get_participation_relation(conversation_id, person_id).update_all({is_read: true})
      end

      def mark_as_unread(conversation_id, person_id)
        get_participation_relation(conversation_id, person_id).update_all({is_read: false})
      end

      def get_participation_relation(conversation_id, person_id)
        ParticipationModel
          .where({conversation_id: conversation_id })
          .where({ person_id: person_id })
      end
    end

    module Query

      module_function

      def conversation_for_person(conversation_id, person_id, community_id)
        conversation = conversations_for_person(person_id, community_id)
          .where({id: conversation_id})
          .first

        if conversation
          Entity.conversation(conversation)
        else
          nil
        end
      end

      def conversations_for_person(person_id, community_id)
        ConversationModel.joins(:participations)
          .where( { participations: { person_id: person_id }} )
          .where(community_id: community_id)
      end
    end
  end
end
