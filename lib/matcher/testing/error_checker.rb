# frozen_string_literal: true

module Matcher
  class ErrorChecker
    def initialize(phrasing)
      @phrasing = phrasing
      @missing_phrases = []
      @extra_phrases = []
      @label_count = 0

      label_counter = proc do |h, k|
        h[k] = (@label_count += 1)
      end

      @element_label_index = Hash.new(&label_counter)
      @group_label_index = Hash.new(&label_counter)
      @hierarchy_index = Hash.new(&label_counter)
      @expression_labeler = ExpressionLabeler.new

      @message_index = Hash.new(&label_counter)
      @phrase_index = Hash.new(&label_counter)

      @identities = Hash.new(&label_counter)
      @phrasing_labels = Hash.new(&label_counter)
    end

    attr_reader :reason, :missing_phrases, :extra_phrases

    def check(expected, actual)
      if expected.valid? && !actual.valid?
        @reason = 'expected no errors'
        return false
      elsif !expected.valid? && actual.valid?
        @reason = 'did not expect no errors'
      end

      expected_tree, expected_leaves = analyze(expected)
      actual_tree, actual_leaves = analyze(actual)

      if actual_tree.label != expected_tree.label
        @reason = 'error has not the expected structure'
        return false
      end

      propagate_hierarchy(expected_tree)
      propagate_hierarchy(actual_tree)

      unless check_phrases(expected_leaves, actual_leaves)
        @reason = 'error has unexpected messages'
        return false
      end

      unless check_trees(expected_tree, actual_tree)
        @reason = 'error tree does not match expected'
        return false
      end

      true
    end

    Tree = Struct.new(
      :label,
      :children,
      :hierarchy,
      :identity,
    ) do
      def leaf?
        false
      end

      def to_s
        "#<Tree #{hierarchy} #{children.map(&:hierarchy).inspect}>"
      end
      alias inspect to_s
    end

    Leaf = Struct.new(
      :label,
      :path,
      :message,
      :hierarchy,
      :identity,
      :message_label,
      :phrase_label,
    ) do
      def leaf?
        true
      end

      def to_s
        "#<Leaf #{hierarchy} #{path} #{message.inspect}>"
      end
      alias inspect to_s
    end

    private

    # assign labels and hierarchy

    def analyze(error)
      leaves = []
      tree = analyze_helper(error, List.empty, ExpressionLabeler::ROOT, leaves)

      [tree, leaves]
    end

    def analyze_helper(error, path, path_label, leaves)
      case error
      when EmptyError
        Tree.new(0)
      when AndError, OrError
        children = error.children
          .map { analyze_helper(_1, path, path_label, leaves) }

        group_key = [error.class, children.map(&:label).sort]
        label = @group_label_index[group_key]

        Tree.new(label, children)
      when NestedError
        new_path_label = @expression_labeler.label(error.key, path_label)

        analyze_helper(error.child, path << error.key, new_path_label, leaves)
      when ElementError
        leaf = Leaf.new
        leaf.label = @element_label_index[path_label]
        leaf.path = path
        leaf.message = error.message

        leaves << leaf

        leaf
      else
        raise "Unexpected error: #{error.inspect}"
      end
    end

    def propagate_hierarchy(node, parent_hierarchy = 0)
      key = [parent_hierarchy, node.label]
      hierarchy = @hierarchy_index[key]
      node.hierarchy = hierarchy
      node.children.each { propagate_hierarchy(_1, hierarchy) } unless node.leaf?
    end

    # message indexing and checking

    def check_phrases(expected_leaves, actual_leaves)
      counts = Hash.new(0)

      actual_leaves.each do |leaf|
        index_message(leaf)
        counts[[leaf.hierarchy, leaf.phrase_label]] += 1
      end

      expected_leaves.each do |leaf|
        index_message(leaf)
        counts[[leaf.hierarchy, leaf.phrase_label]] -= 1
      end

      inverted_phrase_index = @phrase_index.invert

      counts.each do |key, count|
        next if count == 0

        phrase_label = key[1]
        phrase = inverted_phrase_index[phrase_label]

        if count < 0
          @missing_phrases << [phrase, -count]
        else
          @extra_phrases << [phrase, count]
        end
      end

      @missing_phrases.empty? && @extra_phrases.empty?
    end

    def index_message(leaf)
      if leaf.message.is_a?(Message)
        leaf.message_label = @message_index[leaf.message]
        leaf.phrase_label = @phrase_index[phrase(leaf)]
      else
        leaf.phrase_label = @phrase_index[leaf.message]
      end
    end

    def phrase(leaf)
      @phrasing.call(leaf.path, leaf.message)
    end

    # tree matching - Welcome to Overengineering!

    def check_trees(expected_tree, actual_tree)
      identify_tree(actual_tree)

      @actual_hierarchy_groups = group_by_hierarchy(actual_tree)
      @actual_group_phrases_index = index_group_phrases(actual_tree)

      catch(:mismatch) do
        if expected_tree.leaf?
          return false unless actual_tree.leaf?

          if expected_tree.message.is_a?(String)
            return expected_tree.phrase_label == actual_tree.phrase_label
          else
            return expected_tree.message_label == actual_tree.message_label
          end
        elsif actual_tree.leaf?
          return false
        else
          identify_candidates(expected_tree)

          return true
        end
      end

      false
    end

    def group_by_hierarchy(tree, groups = {})
      (groups[tree.hierarchy] ||= []) << tree
      tree.children.each { group_by_hierarchy(_1, groups) } unless tree.leaf?

      groups
    end

    def index_group_phrases(tree)
      index = {}

      index_group_phrases_helper(tree, index) unless tree.leaf?

      index
    end

    def index_group_phrases_helper(tree, index)
      message_counts = Hash.new(0)

      labels = tree.children.filter_map do |child|
        unless child.leaf?
          index_group_phrases_helper(child, index)
          next
        end

        message_counts[child.message_label] += 1 if child.message_label

        child.phrase_label
      end

      unless labels.empty?
        key = [tree.hierarchy, labels.sort!]
        (index[key] ||= []) << [tree.identity, message_counts]
      end

      nil
    end

    def identify_tree(tree)
      content = if tree.leaf?
        tree.message
      else
        tree.children.map { identify_tree(_1) }.sort
      end

      key = [tree.hierarchy, content]
      identity = @identities[key]

      (tree.identity = identity)
    end

    def identify_candidates(expected_tree)
      expected_leaves, expected_parents = expected_tree.children.partition(&:leaf?)

      if expected_leaves.empty?
        actual_group = @actual_hierarchy_groups[expected_tree.hierarchy]

        throw(:mismatch) unless actual_group

        identify_by_parents(expected_parents, actual_group)
      elsif expected_parents.empty?
        identify_by_leaves(expected_leaves, expected_tree.hierarchy)
      else
        leaf_identities = identify_by_leaves(expected_leaves, expected_tree.hierarchy)
        actual_group = @actual_hierarchy_groups[expected_tree.hierarchy]

        throw(:mismatch) unless actual_group

        # NOTE: narrowed_group can't be empty since leaf_identities isn't empty
        narrowed_group = actual_group.filter do |actual_tree|
          leaf_identities.include?(actual_tree.identity)
        end

        identify_by_parents(expected_parents, narrowed_group)
      end
    end

    def identify_by_parents(expected_parents, actual_group)
      positions = expected_parents.map { identify_candidates(_1) }

      throw(:mismatch) if positions.any?(&:empty?)

      candidates = actual_group.filter_map do |actual_tree|
        identities = actual_tree.children.filter_map do |child|
          child.identity unless child.leaf?
        end

        actual_tree.identity if match_identities?(positions, identities)
      end

      throw(:mismatch) if candidates.empty?

      candidates
    end

    def identify_by_leaves(expected_leaves, hierarchy)
      phrase_labels = expected_leaves.map(&:phrase_label)
      group_phrase_label = [hierarchy, phrase_labels.sort!]
      actual_phrase_group = @actual_group_phrases_index[group_phrase_label]

      throw(:mismatch) unless actual_phrase_group

      expected_message_counts = Hash.new(0)
      expected_leaves.each do |leaf|
        expected_message_counts[leaf.message_label] += 1 if leaf.message_label
      end

      candidates = actual_phrase_group.filter_map do |actual_identity, actual_message_counts|
        actual_identity if expected_message_counts.all? do |message_label, expected_message_count|
          expected_message_count <= actual_message_counts[message_label]
        end
      end

      throw(:mismatch) if candidates.empty?

      candidates
    end

    def match_identities?(positions, identities)
      # Prepare NP-hard matching.
      # How did we even get here?! Maybe there's a shortcut!

      # NOTE: candidates_list is now a new array
      positions = positions.map do |candidates|
        intersection = candidates & identities

        # shortcut: no candidate matches any identity
        return false if intersection.empty?

        intersection
      end

      # shortcut: trivial match if candidates are unambiguous
      return positions.map(&:first).sort == identities.sort if
        positions.all? { _1.length == 1 }

      # remap and count identities

      id_map = {}
      id_counts = Array.new(identities.length, 0)

      identities.each do |id|
        index = (id_map[id] ||= id_map.size)
        id_counts[index] += 1
      end

      n = id_map.size
      id_counts = id_counts.slice(0, n) if n < id_counts.length

      # remap and count candidates

      positions.each do |candidates|
        candidates.map! { id_map[_1] }
      end

      candidate_counts = Array.new(n, 0)

      positions.each do |candidates|
        candidates.each { candidate_counts[_1] += 1 }
      end

      # shortcut: too few candidates for identity
      candidate_counts.zip(id_counts) do |candidate_count, id_count|
        return false if candidate_count < id_count
      end

      # sort candidates for early backtracking
      positions.sort_by!(&:length)
      positions.each do |candidates|
        candidates.sort_by! { id_counts[_1] }
      end

      # now the fun begins
      match_identities_helper(positions, id_counts, candidate_counts)
    end

    def match_identities_helper(positions, id_counts, candidate_counts)
      n = positions.length
      stack = Array.new(n)
      j_stack = Array.new(n)

      position = positions[0]
      position.each { candidate_counts[_1] -= 1 }
      candidates = narrow_candidates(position, id_counts, candidate_counts)
      stack[0] = candidates

      i = 0
      j = 0

      # i-loop for position
      loop do
        # assign position and go to next one
        if j < candidates.length
          j_stack[i] = j
          i += 1

          # found a match for all positions
          return true if i == n

          # assign candidate to position
          c = candidates[j]
          id_counts[c] -= 1

          # next candidates
          position = positions[i]
          position.each { candidate_counts[_1] -= 1 }
          candidates = narrow_candidates(position, id_counts, candidate_counts)
          stack[i] = candidates

          j = 0

          next
        end

        # backtracking, j-loop for candidates
        loop do
          # no solution found (back at start)
          return false if i == 0

          stack[i] = nil
          positions[i].each { candidate_counts[_1] += 1 }

          i -= 1

          # unassign previous candidate
          candidates = stack[i]
          j = j_stack[i]
          c = candidates[j]
          id_counts[c] += 1

          j += 1

          # continue backtracking unless untried candidates for position exist
          break if j < candidates.length
        end
      end
    end

    def narrow_candidates(candidates, id_counts, candidate_counts)
      # if there is only one candidate for current position, we can simplify
      if candidates.length == 1
        c = candidates[0]

        # assign position if identity available, otherwise backtrack
        id_counts[c].between?(1, candidate_counts[c] + 1) ? [c] : []
      else
        # do a pre-check if position can be assigned
        #
        # cases:
        # - too few candidates for unassigned identities: backtrack
        #   * diff > 1 for at least one candidate, or
        #   * diff == 1 for more than one candidate
        # - position can only be assigned to one identity: assign
        #   * exactly one diff == 1, all others diff < 1
        # - else: try all candidates for unassigned identities
        #   * diff < 1 for all candidates c where id_counts[c] > 0

        assign = nil

        candidates.each do |c|
          diff = id_counts[c] - candidate_counts[c]

          if diff == 1 && !assign
            assign = c
          elsif diff >= 1
            return [] # backtrack
          end
        end

        assign ? [assign] : candidates.filter { id_counts[_1] > 0 }
      end
    end
  end
end
