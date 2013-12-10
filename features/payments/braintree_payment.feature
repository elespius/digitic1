Feature: User pays accepted request

  Background:
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there are following Braintree accounts:
      | person            | status |
      | kassi_testperson1 | active |
    And community "test" has payments in use via BraintreePaymentGateway
    And Braintree transaction is mocked
    And there is item offer with title "math book" from "kassi_testperson1" and with share type "sell" and with price "12"
    And there is an accepted request for "math book" with price "100" from "kassi_testperson2"

  Scenario:
    Given I am logged in as "kassi_testperson2"
    And I want to pay "math book"
    When I fill in my payment details for Braintree
    And I press submit
    Then I should be see that the payment was successful
    Then "kassi_testperson1" should receive email about payment