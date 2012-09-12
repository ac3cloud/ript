Feature: Error handling
  To ensure that rules apply cleanly
  Ript should validate user input
  And fail gracefully

  @errors @name
  Scenario: Name errors - undefined method
    # should verify no spaces or dashes
    When I run `ript rules generate examples/errors-undefined-method.rb`
    Then the output should match:
      """
      You tried using the '.+' method on line \d+ in .+/errors-undefined-method.rb
      This method doesn't exist in the DSL. Did you mean:

       - ports

      Aborting.
      """
    When I run `ript rules generate examples/errors-undefined-method-with-no-match.rb`
    Then the output should match:
      """
      You tried using the '.+' method on line \d+ in .+/errors-undefined-method-with-no-match.rb
      This method doesn't exist in the DSL. There aren't any other methods with similar names. :-\(
      Aborting.
      """

  @errors @parse @duplicate
  Scenario: Parse errors - duplicate partition name
    # should verify no spaces or dashes
    When I run `ript rules generate examples/duplicate-partition-names/`
    Then the output should match:
      """
      Error: Partition name '\w+' is already defined!
      """

  @errors @parse
  Scenario: Parse errors - bad characters in partition name
    # should verify no spaces or dashes
    When I run `ript rules generate examples/space-in-partition-name.rb`
    Then the output should match:
      """
      Error: Partition name '.+' can't contain whitespace.
      """
    When I run `ript rules generate examples/dash-in-partition-name.rb`
    Then the output should match:
      """
      Error: Partition name '.+' can't contain dashes
      """

  @errors @parse
  Scenario: Parse errors - partition name longer than  characters
    When I run `ript rules generate examples/partition-name-longer-than-20-characters.rb`
    Then the output should match:
      """
      Error: Partition name '.+' cannot be longer than 20 characters.
      """
    When I run `ript rules generate examples/partition-name-exactly-20-characters.rb`
    Then the output should match:
      """
      name_exactly_20_char
      """


  @errors @parse
  Scenario: Parse errors - spaces and dashes
    When I run `ript rules generate examples/space-in-partition-name.rb`
    Then the output should contain:
      """
      Partition name 'space in my name' can't contain whitespace
      """
    When I run `ript rules generate examples/dash-in-partition-name.rb`
    Then the output should contain:
      """
       Partition name 'dash-in-my-name' can't contain dashes ('-')
      """

  @errors @parse
  Scenario: Parse errors - missing address definition
    When I run `ript rules generate examples/missing-address-definition-in-destination.rb`
    Then the output should contain:
      """
      Address 'barprod-web-02' (a destination) isn't defined
      """

  @errors
  Scenario: Parse errors - missing address definition
    When I run `ript rules generate examples/missing-address-definition-in-from.rb`
    Then the output should contain:
      """
      Address 'bad guy' (a from) isn't defined
      """

  @errors
  Scenario: Load errors - missing rule file
    When I run `ript rules generate examples/non-existent-lalalalala.rb`
    Then the output should match:
      """
      The specified rule file or directory 'examples/non-existent-lalalalala.rb' does not exist
      """

  @errors @parse
  Scenario: Multiple partition definitions in the same file
    When I run `ript rules generate examples/multiple-partitions-in-this-file.rb`
    Then the output should match:
      """
      Multiple partition definitions are not permitted in the same file.
      """
