import Foundation

/// Curated bank of DSA problems, written in original phrasing (not scraped
/// from any judge), tagged by topic/company/difficulty for filtering.
/// Company tags reflect commonly-known interview focus areas for that
/// company, not any proprietary or leaked question list.
enum ProblemBank {
    static let all: [Problem] = [

        Problem(
            id: "two-sum",
            title: "Two Sum",
            difficulty: .easy,
            topics: [.arrays],
            companies: [.amazon, .google, .apple, .microsoft, .meta, .linkedin],
            prompt: """
            You're given an array of integers `nums` and an integer `target`. Return the indices \
            of the two numbers that add up exactly to `target`. You may assume each input has \
            exactly one valid answer, and you can't use the same element twice.
            """,
            constraints: ["2 ≤ nums.count ≤ 10^4", "-10^9 ≤ nums[i] ≤ 10^9", "Exactly one valid answer exists"],
            examples: [
                Example(input: "nums = [2,7,11,15], target = 9", output: "[0,1]", explanation: "nums[0] + nums[1] == 9"),
                Example(input: "nums = [3,2,4], target = 6", output: "[1,2]", explanation: nil)
            ],
            hints: [
                "Brute force checks every pair -- that's O(n²). Can you avoid re-scanning the array for the complement?",
                "As you walk the array once, what if you remembered every number you've already seen, along with its index?",
                "A hash map from value → index lets you check 'have I seen target - nums[i] before?' in O(1)."
            ],
            approaches: [
                Approach(name: "Brute force", summary: "Check every pair of indices.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(1)",
                         whenToUse: "Only to build intuition -- too slow for the real constraints.",
                         steps: ["Nested loop over i, j", "Check nums[i] + nums[j] == target", "Return [i, j] on match"]),
                Approach(name: "Hash map (one pass)", summary: "Track seen values and their indices while scanning once.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard optimal solution -- use this in an interview.",
                         steps: ["For each index i", "If target - nums[i] is already in the map, return [map[complement], i]",
                                  "Otherwise store nums[i] → i in the map", "Continue to the next index"])
            ],
            starterCode: [
                .swift: "func twoSum(_ nums: [Int], _ target: Int) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def two_sum(nums: list[int], target: int) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: "Could you do it in one pass without a second lookup loop?"
        ),

        Problem(
            id: "valid-parentheses",
            title: "Valid Parentheses",
            difficulty: .easy,
            topics: [.stack],
            companies: [.amazon, .microsoft, .google, .meta],
            prompt: """
            Given a string containing only the characters `()[]{}`, determine whether the brackets \
            are balanced and correctly nested.
            """,
            constraints: ["1 ≤ s.length ≤ 10^4"],
            examples: [
                Example(input: "s = \"()[]{}\"", output: "true", explanation: nil),
                Example(input: "s = \"(]\"", output: "false", explanation: nil)
            ],
            hints: [
                "Every closing bracket must match the *most recently opened* unmatched bracket -- that's a last-in-first-out pattern.",
                "Push opening brackets onto a stack. On a closing bracket, pop and check it matches.",
                "If the stack isn't empty at the end, something was never closed."
            ],
            approaches: [
                Approach(name: "Stack", summary: "Push openers, pop-and-match on closers.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "This is the canonical solution.",
                         steps: ["Iterate characters", "If opener, push", "If closer, pop and verify it matches",
                                  "At the end, stack must be empty"])
            ],
            starterCode: [
                .swift: "func isValid(_ s: String) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def is_valid(s: str) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "best-time-to-buy-sell-stock",
            title: "Best Time to Buy and Sell Stock",
            difficulty: .easy,
            topics: [.arrays, .greedy],
            companies: [.amazon, .apple],
            prompt: """
            You're given an array `prices` where `prices[i]` is the price of a stock on day `i`. \
            You may buy on one day and sell on a later day. Return the maximum profit you can \
            achieve, or 0 if no profit is possible.
            """,
            constraints: ["1 ≤ prices.count ≤ 10^5", "0 ≤ prices[i] ≤ 10^4"],
            examples: [
                Example(input: "prices = [7,1,5,3,6,4]", output: "5", explanation: "Buy on day 2 (price 1), sell on day 5 (price 6)."),
                Example(input: "prices = [7,6,4,3,1]", output: "0", explanation: "Prices only fall -- no profit possible.")
            ],
            hints: [
                "You only ever need to remember the lowest price seen so far.",
                "At each day, ask: 'if I sold today, what's my profit given the cheapest buy so far?'",
                "Track a running minimum and a running best profit in a single pass."
            ],
            approaches: [
                Approach(name: "Brute force", summary: "Try every buy/sell pair.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(1)",
                         whenToUse: "Too slow for real constraints -- for intuition only.",
                         steps: ["Nested loop over buy day i, sell day j > i", "Track max(prices[j] - prices[i])"]),
                Approach(name: "One-pass min tracking", summary: "Track the minimum price so far and best profit so far.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "Optimal -- use this.",
                         steps: ["minPrice = prices[0]", "For each price: update minPrice = min(minPrice, price)",
                                  "bestProfit = max(bestProfit, price - minPrice)"])
            ],
            starterCode: [
                .swift: "func maxProfit(_ prices: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def max_profit(prices: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "What changes if you're allowed unlimited buy/sell transactions?"
        ),

        Problem(
            id: "longest-substring-no-repeat",
            title: "Longest Substring Without Repeating Characters",
            difficulty: .medium,
            topics: [.slidingWindow, .arrays],
            companies: [.amazon, .microsoft, .apple, .google, .meta],
            prompt: """
            Given a string `s`, find the length of the longest substring that contains no \
            repeating characters.
            """,
            constraints: ["0 ≤ s.length ≤ 5 × 10^4", "s consists of English letters, digits, symbols and spaces"],
            examples: [
                Example(input: "s = \"abcabcbb\"", output: "3", explanation: "\"abc\" is the longest without repeats."),
                Example(input: "s = \"bbbbb\"", output: "1", explanation: nil)
            ],
            hints: [
                "A brute force checks every substring -- O(n³) or O(n²). Can a window that grows and shrinks do better?",
                "Keep a window [left, right] with no duplicates. When you hit a duplicate, shrink from the left past it.",
                "A set (or a dictionary of last-seen index) lets you jump `left` directly past the duplicate instead of stepping one at a time."
            ],
            approaches: [
                Approach(name: "Brute force", summary: "Check every substring for uniqueness.",
                         timeComplexity: "O(n³)", spaceComplexity: "O(min(n, alphabet))",
                         whenToUse: "For intuition only.",
                         steps: ["Try every (i, j) pair", "Check substring s[i...j] has no repeats", "Track max length"]),
                Approach(name: "Sliding window + set", summary: "Expand right, shrink left on duplicate.",
                         timeComplexity: "O(n)", spaceComplexity: "O(min(n, alphabet))",
                         whenToUse: "Optimal solution.",
                         steps: ["left = 0, set = {}", "For right in 0..<n: while s[right] in set, remove s[left] and left += 1",
                                  "Add s[right] to set", "maxLen = max(maxLen, right - left + 1)"]),
                Approach(name: "Sliding window + last-seen index", summary: "Jump left directly to just past the last occurrence.",
                         timeComplexity: "O(n)", spaceComplexity: "O(alphabet)",
                         whenToUse: "Slightly faster in practice -- avoids the inner while loop.",
                         steps: ["Map char → last index seen", "On repeat, move left to max(left, lastSeen[char] + 1)",
                                  "Update lastSeen[char] = right each step"])
            ],
            starterCode: [
                .swift: "func lengthOfLongestSubstring(_ s: String) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def length_of_longest_substring(s: str) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "merge-intervals",
            title: "Merge Intervals",
            difficulty: .medium,
            topics: [.intervals, .arrays],
            companies: [.google, .amazon, .microsoft, .uber, .netflix],
            prompt: """
            Given an array of intervals `[start, end]`, merge all overlapping intervals and \
            return the resulting non-overlapping intervals, sorted by start.
            """,
            constraints: ["1 ≤ intervals.count ≤ 10^4", "0 ≤ start ≤ end ≤ 10^5"],
            examples: [
                Example(input: "[[1,3],[2,6],[8,10],[15,18]]", output: "[[1,6],[8,10],[15,18]]",
                        explanation: "[1,3] and [2,6] overlap → merge to [1,6]."),
                Example(input: "[[1,4],[4,5]]", output: "[[1,5]]", explanation: "Touching intervals count as overlapping.")
            ],
            hints: [
                "Overlap is easy to detect once intervals are sorted by start -- unsorted, you'd have to compare everything to everything.",
                "Sort by start, then walk through: if the current interval's start is ≤ the last merged interval's end, merge them.",
                "Merging just means extending the last merged interval's end to max(lastEnd, currentEnd)."
            ],
            approaches: [
                Approach(name: "Sort + linear merge", summary: "Sort by start, then greedily extend the last interval.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard optimal approach.",
                         steps: ["Sort intervals by start", "result = [intervals[0]]",
                                  "For each next interval: if it overlaps result.last, extend result.last.end",
                                  "Otherwise append it as a new interval"])
            ],
            starterCode: [
                .swift: "func merge(_ intervals: [[Int]]) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def merge(intervals: list[list[int]]) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: "How would you handle inserting one new interval into an already-merged, sorted list efficiently?"
        ),

        Problem(
            id: "linked-list-cycle",
            title: "Linked List Cycle",
            difficulty: .easy,
            topics: [.linkedList, .twoPointers],
            companies: [.amazon, .microsoft],
            prompt: "Given the head of a linked list, determine whether the list contains a cycle.",
            constraints: ["0 ≤ number of nodes ≤ 10^4"],
            examples: [
                Example(input: "3 -> 2 -> 0 -> -4 -> (back to 2)", output: "true", explanation: nil),
                Example(input: "1 -> 2 -> null", output: "false", explanation: nil)
            ],
            hints: [
                "You could store every visited node in a set -- but that costs O(n) extra space. Can you avoid that?",
                "Imagine two runners on the list, one twice as fast as the other. What happens if the track is a loop?",
                "Floyd's cycle detection: a slow pointer moves 1 step, a fast pointer moves 2. If they ever meet, there's a cycle."
            ],
            approaches: [
                Approach(name: "Hash set of visited nodes", summary: "Track every node you've seen.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Simple and correct, but not the space-optimal answer interviewers expect.",
                         steps: ["Walk the list, insert each node into a set", "If you see a node already in the set, there's a cycle"]),
                Approach(name: "Floyd's slow/fast pointers", summary: "Two pointers at different speeds must meet inside a cycle.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The expected optimal solution.",
                         steps: ["slow = head, fast = head", "Loop: slow = slow.next, fast = fast.next.next",
                                  "If fast or fast.next is nil, no cycle", "If slow == fast, cycle found"])
            ],
            starterCode: [
                .swift: "// class ListNode { var val: Int; var next: ListNode?; init(_ v: Int) { val = v } }\nfunc hasCycle(_ head: ListNode?) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "# class ListNode:\n#     def __init__(self, val=0, next=None):\n#         self.val, self.next = val, next\ndef has_cycle(head) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: "Can you find the node where the cycle *begins*, still in O(1) space?"
        ),

        Problem(
            id: "binary-tree-level-order",
            title: "Binary Tree Level Order Traversal",
            difficulty: .medium,
            topics: [.trees],
            companies: [.amazon, .google, .microsoft, .linkedin],
            prompt: "Given the root of a binary tree, return the values of its nodes grouped level by level (top to bottom, left to right within each level).",
            constraints: ["0 ≤ number of nodes ≤ 2000"],
            examples: [
                Example(input: "[3,9,20,null,null,15,7]", output: "[[3],[9,20],[15,7]]", explanation: nil)
            ],
            hints: [
                "Depth-first recursion can do this, but you'd need to track depth explicitly to group nodes by level.",
                "A breadth-first traversal naturally visits nodes level by level -- what data structure processes items in the order they arrive?",
                "Use a queue. At each iteration, drain exactly the nodes currently in the queue (that's one full level) before enqueuing their children."
            ],
            approaches: [
                Approach(name: "BFS with queue", summary: "Process one full level per iteration using the queue's current size.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The natural, optimal approach for level-order problems.",
                         steps: ["queue = [root] (if non-nil)", "While queue not empty: levelSize = queue.count",
                                  "Pop exactly levelSize nodes, collect their values, enqueue their children",
                                  "Append the collected values as one level"]),
                Approach(name: "DFS with depth tracking", summary: "Recurse while passing the current depth; append to result[depth].",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Also valid -- useful if you prefer recursion.",
                         steps: ["dfs(node, depth): if depth == result.count, append new empty level",
                                  "result[depth].append(node.val)", "recurse into left/right with depth + 1"])
            ],
            starterCode: [
                .swift: "// class TreeNode { var val: Int; var left: TreeNode?; var right: TreeNode?; init(_ v: Int) { val = v } }\nfunc levelOrder(_ root: TreeNode?) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "# class TreeNode:\n#     def __init__(self, val=0, left=None, right=None):\n#         self.val, self.left, self.right = val, left, right\ndef level_order(root) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: "How would you do a zig-zag level order (alternating left-to-right, right-to-left)?"
        ),

        Problem(
            id: "validate-bst",
            title: "Validate Binary Search Tree",
            difficulty: .medium,
            topics: [.trees],
            companies: [.microsoft, .amazon, .apple],
            prompt: "Given the root of a binary tree, determine whether it is a valid binary search tree (BST).",
            constraints: ["1 ≤ number of nodes ≤ 10^4", "-2^31 ≤ Node.val ≤ 2^31 - 1"],
            examples: [
                Example(input: "[2,1,3]", output: "true", explanation: nil),
                Example(input: "[5,1,4,null,null,3,6]", output: "false", explanation: "4's right child 3 is less than 4's ancestor 5's left subtree bound violates BST property.")
            ],
            hints: [
                "Just checking node.left.val < node.val < node.right.val locally isn't enough -- a whole subtree must stay within bounds, not just the immediate children.",
                "Carry a valid (lowerBound, upperBound) range down the recursion, tightening it as you descend left or right.",
                "An in-order traversal of a valid BST also produces strictly increasing values -- that's an alternative check."
            ],
            approaches: [
                Approach(name: "Bounded recursion", summary: "Pass down a valid (min, max) range for each subtree.",
                         timeComplexity: "O(n)", spaceComplexity: "O(h) recursion stack",
                         whenToUse: "Most direct and interview-expected approach.",
                         steps: ["validate(node, lower, upper)", "if node is nil, return true",
                                  "if not (lower < node.val < upper), return false",
                                  "return validate(left, lower, node.val) && validate(right, node.val, upper)"]),
                Approach(name: "In-order traversal", summary: "Values must come out strictly increasing.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Good alternative, easy to explain.",
                         steps: ["In-order traverse (left, node, right)", "Track previous value",
                                  "If current ≤ previous at any point, invalid"])
            ],
            starterCode: [
                .swift: "// class TreeNode { var val: Int; var left: TreeNode?; var right: TreeNode?; init(_ v: Int) { val = v } }\nfunc isValidBST(_ root: TreeNode?) -> Bool {\n    // Write your solution here\n    return true\n}\n",
                .python: "def is_valid_bst(root) -> bool:\n    # Write your solution here\n    return True\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "course-schedule",
            title: "Course Schedule",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.google, .amazon, .uber, .meta],
            prompt: """
            There are `numCourses` courses labeled 0 to numCourses-1. `prerequisites[i] = [a, b]` \
            means you must take course `b` before course `a`. Return true if you can finish all \
            courses (i.e. there's no cyclic dependency).
            """,
            constraints: ["1 ≤ numCourses ≤ 2000", "0 ≤ prerequisites.count ≤ 5000"],
            examples: [
                Example(input: "numCourses = 2, prerequisites = [[1,0]]", output: "true", explanation: "Take 0, then 1."),
                Example(input: "numCourses = 2, prerequisites = [[1,0],[0,1]]", output: "false", explanation: "0 needs 1 and 1 needs 0 -- a cycle.")
            ],
            hints: [
                "This is really a graph question in disguise: courses are nodes, prerequisites are directed edges. What property makes a directed graph impossible to fully order?",
                "A graph can be fully ordered (topologically sorted) exactly when it has no cycle.",
                "Detect cycles with DFS using three states per node (unvisited / visiting / done), or do a Kahn's-algorithm topological sort with in-degrees."
            ],
            approaches: [
                Approach(name: "DFS with 3-color cycle detection", summary: "Mark nodes visiting/done; a re-visit of a 'visiting' node means a cycle.",
                         timeComplexity: "O(V + E)", spaceComplexity: "O(V + E)",
                         whenToUse: "Clean and intuitive for most people.",
                         steps: ["Build adjacency list from prerequisites", "DFS each unvisited node, marking state = visiting",
                                  "If you reach a node already 'visiting', cycle found -> return false",
                                  "Mark 'done' after exploring all neighbors"]),
                Approach(name: "Kahn's algorithm (BFS topological sort)", summary: "Repeatedly remove nodes with in-degree 0.",
                         timeComplexity: "O(V + E)", spaceComplexity: "O(V + E)",
                         whenToUse: "Also gives you the actual course ordering as a bonus.",
                         steps: ["Compute in-degree for every course", "Queue all courses with in-degree 0",
                                  "Pop a course, 'take' it, decrement neighbors' in-degree, enqueue any that hit 0",
                                  "If you processed all courses, no cycle; otherwise a cycle exists"])
            ],
            starterCode: [
                .swift: "func canFinish(_ numCourses: Int, _ prerequisites: [[Int]]) -> Bool {\n    // Write your solution here\n    return true\n}\n",
                .python: "def can_finish(num_courses: int, prerequisites: list[list[int]]) -> bool:\n    # Write your solution here\n    return True\n"
            ],
            followUp: "Can you return one valid course ordering instead of just true/false?"
        ),

        Problem(
            id: "climbing-stairs",
            title: "Climbing Stairs",
            difficulty: .easy,
            topics: [.dynamicProgramming],
            companies: [.amazon, .apple],
            prompt: "You're climbing a staircase with `n` steps. Each move you can climb 1 or 2 steps. How many distinct ways can you reach the top?",
            constraints: ["1 ≤ n ≤ 45"],
            examples: [
                Example(input: "n = 2", output: "2", explanation: "1+1 or 2"),
                Example(input: "n = 3", output: "3", explanation: "1+1+1, 1+2, 2+1")
            ],
            hints: [
                "How many ways to reach step n? Think about the very last move you take -- it was either a 1-step or a 2-step.",
                "ways(n) = ways(n-1) + ways(n-2) -- does that pattern look familiar?",
                "This is Fibonacci in disguise. You don't need recursion with memo -- two rolling variables give O(1) space."
            ],
            approaches: [
                Approach(name: "Naive recursion", summary: "Directly recurse ways(n) = ways(n-1) + ways(n-2).",
                         timeComplexity: "O(2^n)", spaceComplexity: "O(n) stack",
                         whenToUse: "Illustrates the recurrence, but exponential blowup without memoization.",
                         steps: ["Base cases n ≤ 2", "Return ways(n-1) + ways(n-2)"]),
                Approach(name: "Bottom-up DP / rolling variables", summary: "Build up from step 1 using two running totals.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "Optimal -- this is what you should code in an interview.",
                         steps: ["prev2 = 1, prev1 = 1", "For i in 2...n: current = prev1 + prev2; prev2 = prev1; prev1 = current",
                                  "Return prev1"])
            ],
            starterCode: [
                .swift: "func climbStairs(_ n: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def climb_stairs(n: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "What if a move can also be 3 steps? Does the O(1)-space trick still work?"
        ),

        Problem(
            id: "coin-change",
            title: "Coin Change",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.amazon, .google, .microsoft, .openai],
            prompt: "Given coin denominations `coins` and a target `amount`, return the fewest number of coins needed to make that amount, or -1 if it's impossible.",
            constraints: ["1 ≤ coins.count ≤ 12", "1 ≤ coins[i] ≤ 2^31 - 1", "0 ≤ amount ≤ 10^4"],
            examples: [
                Example(input: "coins = [1,2,5], amount = 11", output: "3", explanation: "5 + 5 + 1"),
                Example(input: "coins = [2], amount = 3", output: "-1", explanation: nil)
            ],
            hints: [
                "Greedy (always take the biggest coin) fails for some denominations -- can you think of a counter-example? That rules out a purely greedy approach.",
                "Define dp[x] = fewest coins to make amount x. How does dp[x] relate to dp[x - coin] for each coin?",
                "dp[x] = 1 + min(dp[x - coin]) over all coins ≤ x, with dp[0] = 0 as the base case."
            ],
            approaches: [
                Approach(name: "Greedy", summary: "Always use the largest coin that fits.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(1)",
                         whenToUse: "Only correct for 'canonical' coin systems (like US coins) -- not general. Avoid unless the problem guarantees it.",
                         steps: ["Sort coins descending", "Repeatedly subtract the largest coin that fits", "Count coins used"]),
                Approach(name: "Bottom-up DP", summary: "dp[x] = fewest coins for amount x, built up from 0.",
                         timeComplexity: "O(amount × coins.count)", spaceComplexity: "O(amount)",
                         whenToUse: "The general, always-correct optimal solution.",
                         steps: ["dp = array of size amount+1, filled with infinity; dp[0] = 0",
                                  "For x in 1...amount: for each coin ≤ x: dp[x] = min(dp[x], dp[x-coin] + 1)",
                                  "Return dp[amount] if finite, else -1"])
            ],
            starterCode: [
                .swift: "func coinChange(_ coins: [Int], _ amount: Int) -> Int {\n    // Write your solution here\n    return -1\n}\n",
                .python: "def coin_change(coins: list[int], amount: int) -> int:\n    # Write your solution here\n    return -1\n"
            ],
            followUp: "Can you also return *which* coins were used, not just the count?"
        ),

        Problem(
            id: "kth-largest-element",
            title: "Kth Largest Element in an Array",
            difficulty: .medium,
            topics: [.heaps, .arrays],
            companies: [.amazon, .apple, .microsoft, .meta],
            prompt: "Given an integer array `nums` and an integer `k`, return the k-th largest element (not the k-th distinct element).",
            constraints: ["1 ≤ k ≤ nums.count ≤ 10^5"],
            examples: [
                Example(input: "nums = [3,2,1,5,6,4], k = 2", output: "5", explanation: nil)
            ],
            hints: [
                "Sorting the whole array works but does more work than needed -- O(n log n) when you only care about one position.",
                "A min-heap of size k, where you push everything but pop whenever the heap exceeds size k, keeps exactly the k largest seen so far.",
                "After processing all elements, the top of that min-heap is the k-th largest."
            ],
            approaches: [
                Approach(name: "Sort", summary: "Sort descending, index k-1.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(log n) or O(n)",
                         whenToUse: "Simple and fine unless the interviewer wants better.",
                         steps: ["Sort nums descending", "Return nums[k-1]"]),
                Approach(name: "Min-heap of size k", summary: "Maintain the k largest elements seen so far.",
                         timeComplexity: "O(n log k)", spaceComplexity: "O(k)",
                         whenToUse: "Better when k is much smaller than n, or with a streaming input.",
                         steps: ["Push elements onto a min-heap", "If heap size exceeds k, pop the minimum",
                                  "After processing all elements, the heap's minimum is the answer"]),
                Approach(name: "Quickselect", summary: "Partition like quicksort, but only recurse into the side containing the answer.",
                         timeComplexity: "O(n) average, O(n²) worst case", spaceComplexity: "O(1)",
                         whenToUse: "Fastest average case -- great follow-up answer if asked to beat O(n log n).",
                         steps: ["Pick a pivot, partition around it", "If pivot lands at index n-k, done",
                                  "Otherwise recurse into only the half containing index n-k"])
            ],
            starterCode: [
                .swift: "func findKthLargest(_ nums: [Int], _ k: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def find_kth_largest(nums: list[int], k: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "word-search",
            title: "Word Search",
            difficulty: .medium,
            topics: [.backtracking],
            companies: [.amazon, .microsoft, .meta],
            prompt: "Given an `m x n` grid of characters and a string `word`, return true if `word` can be formed by a path of adjacent cells (up/down/left/right), using each cell at most once.",
            constraints: ["1 ≤ m, n ≤ 6", "1 ≤ word.length ≤ 15"],
            examples: [
                Example(input: "board = [[A,B,C,E],[S,F,C,S],[A,D,E,E]], word = \"ABCCED\"", output: "true", explanation: nil)
            ],
            hints: [
                "You need to explore paths and be able to abandon ones that don't work -- that's a signal for backtracking / DFS.",
                "Try starting the search from every cell that matches word[0].",
                "Mark a cell as visited before recursing into neighbors, and un-mark it ('backtrack') after -- so it can be reused on a different path."
            ],
            approaches: [
                Approach(name: "Backtracking DFS", summary: "DFS from each matching start cell, marking/unmarking visited cells.",
                         timeComplexity: "O(m·n·4^L) where L = word length", spaceComplexity: "O(L) recursion stack",
                         whenToUse: "The standard, expected solution.",
                         steps: ["For each cell matching word[0], start dfs(cell, 0)",
                                  "dfs(cell, i): if i == word.count, return true",
                                  "If out of bounds/mismatch/visited, return false",
                                  "Mark visited, recurse into 4 neighbors with i+1, then un-mark before returning"])
            ],
            starterCode: [
                .swift: "func exist(_ board: [[Character]], _ word: String) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def exist(board: list[list[str]], word: str) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "lru-cache",
            title: "LRU Cache",
            difficulty: .medium,
            topics: [.linkedList, .arrays],
            companies: [.amazon, .google, .microsoft, .apple, .meta, .netflix, .uber, .openai],
            prompt: """
            Design a Least Recently Used (LRU) cache with a fixed `capacity`. It should support \
            `get(key)` in O(1), returning -1 if the key isn't present, and `put(key, value)` in \
            O(1), evicting the least recently used entry when the cache is full.
            """,
            constraints: ["1 ≤ capacity ≤ 3000", "up to 2 × 10^5 calls to get/put"],
            examples: [
                Example(input: "capacity=2; put(1,1); put(2,2); get(1)->1; put(3,3) evicts 2; get(2)->-1",
                        output: "see explanation", explanation: nil)
            ],
            hints: [
                "A plain dictionary gives O(1) get/put but has no notion of 'order of use' -- you need something that also tracks recency.",
                "A doubly linked list lets you move a node to the front (most-recently-used) in O(1), and evict from the back in O(1).",
                "Combine both: a hash map from key → linked-list node, plus a doubly linked list ordered by recency."
            ],
            approaches: [
                Approach(name: "Hash map + doubly linked list", summary: "Map key → node; list keeps recency order for O(1) evict/promote.",
                         timeComplexity: "O(1) per operation", spaceComplexity: "O(capacity)",
                         whenToUse: "This is the expected, and essentially only, good solution.",
                         steps: ["get(key): if present, move node to front, return value; else -1",
                                  "put(key,value): if present, update + move to front",
                                  "If new and at capacity, remove the tail (LRU) node and its map entry",
                                  "Insert new node at the front, add to map"])
            ],
            starterCode: [
                .swift: "final class LRUCache {\n    init(_ capacity: Int) {\n        // Write your solution here\n    }\n    func get(_ key: Int) -> Int {\n        return -1\n    }\n    func put(_ key: Int, _ value: Int) {\n    }\n}\n",
                .python: "class LRUCache:\n    def __init__(self, capacity: int):\n        pass\n    def get(self, key: int) -> int:\n        return -1\n    def put(self, key: int, value: int) -> None:\n        pass\n"
            ],
            followUp: "How would you make this thread-safe for concurrent access?"
        ),

        Problem(
            id: "median-two-sorted-arrays",
            title: "Median of Two Sorted Arrays",
            difficulty: .hard,
            topics: [.binarySearch, .arrays],
            companies: [.google, .apple, .amazon],
            prompt: "Given two sorted arrays `nums1` and `nums2`, return the median of the two arrays combined, in O(log(m+n)) time.",
            constraints: ["0 ≤ m, n ≤ 1000", "1 ≤ m + n ≤ 2000"],
            examples: [
                Example(input: "nums1 = [1,3], nums2 = [2]", output: "2.0", explanation: nil),
                Example(input: "nums1 = [1,2], nums2 = [3,4]", output: "2.5", explanation: nil)
            ],
            hints: [
                "Merging both arrays gives the median trivially, but that's O(m+n) -- the log(m+n) requirement is a strong hint toward binary search.",
                "The median splits the combined array into a left half and right half of (nearly) equal size. You just need to find where that split falls in each array.",
                "Binary search on the smaller array for a partition index; the partition in the other array is then determined by the sizes. Adjust until max(left parts) ≤ min(right parts)."
            ],
            approaches: [
                Approach(name: "Merge (naive)", summary: "Merge both sorted arrays, then read off the median.",
                         timeComplexity: "O(m+n)", spaceComplexity: "O(m+n)",
                         whenToUse: "Fine as a warm-up answer, but doesn't meet the log-time requirement.",
                         steps: ["Two-pointer merge nums1 and nums2 into one sorted array", "Return middle element(s)"]),
                Approach(name: "Binary search on partitions", summary: "Binary search the smaller array for the correct partition point.",
                         timeComplexity: "O(log(min(m, n)))", spaceComplexity: "O(1)",
                         whenToUse: "The intended optimal solution -- a classic hard-tier binary search problem.",
                         steps: ["Ensure nums1 is the shorter array", "Binary search partition i in nums1; derive partition j in nums2 from i and total length",
                                  "Check max(left1,left2) ≤ min(right1,right2); adjust i via binary search until true",
                                  "Compute median from the boundary elements, handling odd/even total length"])
            ],
            starterCode: [
                .swift: "func findMedianSortedArrays(_ nums1: [Int], _ nums2: [Int]) -> Double {\n    // Write your solution here\n    return 0.0\n}\n",
                .python: "def find_median_sorted_arrays(nums1: list[int], nums2: list[int]) -> float:\n    # Write your solution here\n    return 0.0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "number-of-islands",
            title: "Number of Islands",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.amazon, .google, .microsoft, .meta],
            prompt: "Given an `m x n` binary grid where '1' is land and '0' is water, return the number of islands (land connected horizontally/vertically).",
            constraints: ["1 ≤ m, n ≤ 300"],
            examples: [
                Example(input: "[[1,1,0,0],[1,1,0,0],[0,0,1,0],[0,0,0,1]]", output: "3", explanation: nil)
            ],
            hints: [
                "This is a connected-components problem on a grid -- each island is one connected component of land cells.",
                "Scan every cell; whenever you find unvisited land, that's a *new* island -- flood-fill from there to mark the whole island visited.",
                "DFS, BFS, or Union-Find all work for the flood fill. DFS/BFS are simplest to write under time pressure."
            ],
            approaches: [
                Approach(name: "DFS flood fill", summary: "On each unvisited '1', DFS to sink the whole island, incrementing a counter once per island.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(m·n) worst-case recursion stack",
                         whenToUse: "Simplest to write; the standard answer.",
                         steps: ["For each cell: if land and unvisited, count += 1 and dfs to mark the whole island visited",
                                  "dfs(r,c): if out of bounds/water/visited, return; mark visited; recurse into 4 neighbors"]),
                Approach(name: "BFS flood fill", summary: "Same idea, iterative with a queue instead of recursion.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(min(m,n))",
                         whenToUse: "Avoids recursion depth issues on very large grids.",
                         steps: ["Same outer scan", "On new land, BFS with a queue, marking visited as you enqueue"]),
                Approach(name: "Union-Find", summary: "Union adjacent land cells; count distinct roots.",
                         timeComplexity: "O(m·n·α(m·n))", spaceComplexity: "O(m·n)",
                         whenToUse: "Great follow-up if asked about dynamic/streaming grid updates.",
                         steps: ["Union each land cell with its land neighbors", "Count distinct roots among land cells"])
            ],
            starterCode: [
                .swift: "func numIslands(_ grid: [[Character]]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def num_islands(grid: list[list[str]]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "product-except-self",
            title: "Product of Array Except Self",
            difficulty: .medium,
            topics: [.arrays],
            companies: [.amazon, .apple, .microsoft, .meta],
            prompt: "Given an array `nums`, return an array `answer` where `answer[i]` is the product of all elements except `nums[i]`, without using division and in O(n) time.",
            constraints: ["2 ≤ nums.count ≤ 10^5"],
            examples: [
                Example(input: "nums = [1,2,3,4]", output: "[24,12,8,6]", explanation: nil)
            ],
            hints: [
                "Without division, you can't just compute the total product and divide it out.",
                "answer[i] = (product of everything to the left of i) × (product of everything to the right of i).",
                "Compute left-running-products in one pass, then fold in right-running-products in a second pass, reusing the output array to keep space O(1) extra."
            ],
            approaches: [
                Approach(name: "Prefix × suffix products", summary: "Two passes: left-products forward, right-products backward, multiplied together.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1) extra (excluding output array)",
                         whenToUse: "The expected optimal solution.",
                         steps: ["answer[0] = 1; for i in 1..<n: answer[i] = answer[i-1] * nums[i-1] (left products)",
                                  "right = 1; for i in stride(from: n-1, through: 0, by: -1): answer[i] *= right; right *= nums[i]"])
            ],
            starterCode: [
                .swift: "func productExceptSelf(_ nums: [Int]) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def product_except_self(nums: list[int]) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "top-k-frequent-elements",
            title: "Top K Frequent Elements",
            difficulty: .medium,
            topics: [.heaps, .arrays],
            companies: [.amazon, .google, .meta, .twitter, .netflix],
            prompt: "Given an integer array `nums` and an integer `k`, return the `k` most frequent elements, in any order.",
            constraints: ["1 ≤ nums.count ≤ 10^5", "k is between 1 and the number of distinct elements"],
            examples: [
                Example(input: "nums = [1,1,1,2,2,3], k = 2", output: "[1,2]", explanation: nil)
            ],
            hints: [
                "First count frequencies with a hash map -- that part is unavoidable and O(n).",
                "Sorting all distinct values by frequency works but is more than necessary when k is small.",
                "Bucket sort by frequency (index = frequency, bucket contains all values with that frequency) gives O(n) overall, or a size-k heap gives O(n log k)."
            ],
            approaches: [
                Approach(name: "Sort by frequency", summary: "Count frequencies, sort distinct values by count descending, take top k.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(n)",
                         whenToUse: "Simple and usually accepted.",
                         steps: ["Count with a hash map", "Sort entries by count descending", "Take first k keys"]),
                Approach(name: "Bucket sort by frequency", summary: "Index buckets by frequency (max possible = n); read off top k from the top.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Optimal linear-time approach -- a strong answer if asked to beat n log n.",
                         steps: ["Count frequencies", "buckets[freq].append(value) for each distinct value",
                                  "Walk buckets from n down to 1, collecting values until you have k"])
            ],
            starterCode: [
                .swift: "func topKFrequent(_ nums: [Int], _ k: Int) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def top_k_frequent(nums: list[int], k: int) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "reverse-linked-list",
            title: "Reverse Linked List",
            difficulty: .easy,
            topics: [.linkedList],
            companies: [.amazon, .microsoft, .apple],
            prompt: "Given the head of a singly linked list, reverse the list and return the new head.",
            constraints: ["0 ≤ number of nodes ≤ 5000"],
            examples: [
                Example(input: "1 -> 2 -> 3 -> 4 -> 5", output: "5 -> 4 -> 3 -> 2 -> 1", explanation: nil)
            ],
            hints: [
                "You can't just flip 'next' pointers in place without losing the rest of the list -- you need to remember where you're going before you rewire where you came from.",
                "Keep three pointers as you walk: previous, current, and next (saved before you overwrite current.next).",
                "At each step: save next, point current.next back at previous, then advance previous and current forward."
            ],
            approaches: [
                Approach(name: "Iterative pointer reversal", summary: "Walk the list once, flipping each node's next pointer.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "Standard, expected solution.",
                         steps: ["prev = nil, curr = head", "While curr != nil: next = curr.next; curr.next = prev; prev = curr; curr = next",
                                  "Return prev as the new head"]),
                Approach(name: "Recursive", summary: "Reverse the rest of the list, then fix up the current node's links.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n) call stack",
                         whenToUse: "Elegant, but uses more space -- good to mention as an alternative.",
                         steps: ["Base case: nil or single node returns itself", "newHead = reverse(head.next)",
                                  "head.next.next = head; head.next = nil", "Return newHead"])
            ],
            starterCode: [
                .swift: "func reverseList(_ head: ListNode?) -> ListNode? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def reverse_list(head):\n    # Write your solution here\n    return None\n"
            ],
            followUp: "Can you reverse just a sub-section of the list, between positions left and right?"
        ),

        Problem(
            id: "maximum-subarray",
            title: "Maximum Subarray",
            difficulty: .medium,
            topics: [.dynamicProgramming, .arrays],
            companies: [.amazon, .microsoft, .google, .meta],
            prompt: "Given an integer array `nums`, find the contiguous subarray with the largest sum and return that sum.",
            constraints: ["1 ≤ nums.count ≤ 10^5", "-10^4 ≤ nums[i] ≤ 10^4"],
            examples: [
                Example(input: "nums = [-2,1,-3,4,-1,2,1,-5,4]", output: "6", explanation: "[4,-1,2,1] sums to 6.")
            ],
            hints: [
                "At each position, ask: is it better to extend the previous subarray, or start fresh from here?",
                "If the running sum so far is negative, it can only be dragging future sums down -- better to restart at the current element.",
                "This is Kadane's algorithm: track a running 'best sum ending here' and a global best."
            ],
            approaches: [
                Approach(name: "Kadane's algorithm", summary: "Track the best sum ending at each index, resetting when it goes negative.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The optimal, expected solution.",
                         steps: ["currentSum = nums[0], best = nums[0]",
                                  "For each subsequent num: currentSum = max(num, currentSum + num)",
                                  "best = max(best, currentSum)"]),
                Approach(name: "Divide and conquer", summary: "Recursively split in half; best is max of left, right, or crossing-the-middle.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(log n)",
                         whenToUse: "Good follow-up if asked for an alternative to Kadane's.",
                         steps: ["Split array in half", "Recurse for best-in-left and best-in-right",
                                  "Compute best crossing the midpoint by extending outward from center",
                                  "Return the max of the three"])
            ],
            starterCode: [
                .swift: "func maxSubArray(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def max_sub_array(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "Can you also return the actual subarray, not just its sum?"
        ),

        Problem(
            id: "trapping-rain-water",
            title: "Trapping Rain Water",
            difficulty: .hard,
            topics: [.twoPointers, .arrays],
            companies: [.amazon, .google, .apple, .meta],
            prompt: "Given `n` non-negative integers representing an elevation map where each bar has width 1, compute how much water it can trap after raining.",
            constraints: ["1 ≤ n ≤ 2 × 10^4"],
            examples: [
                Example(input: "height = [0,1,0,2,1,0,1,3,2,1,2,1]", output: "6", explanation: nil)
            ],
            hints: [
                "Water trapped above index i is limited by the shorter of the tallest bar to its left and the tallest bar to its right, minus height[i].",
                "Precomputing left-max and right-max arrays gives an O(n) solution directly -- but can you avoid the extra arrays?",
                "Two pointers from both ends: move the side with the smaller current max inward, since that side's bound is already known to be the limiting one."
            ],
            approaches: [
                Approach(name: "Left-max / right-max arrays", summary: "Precompute max height to the left and right of every index.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Easiest to derive first; good stepping stone to the O(1)-space version.",
                         steps: ["leftMax[i] = max height in height[0...i]", "rightMax[i] = max height in height[i...n-1]",
                                  "water[i] = max(0, min(leftMax[i], rightMax[i]) - height[i])", "Sum water[i]"]),
                Approach(name: "Two pointers", summary: "Converge from both ends, always advancing the side with the smaller max.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The fully optimal solution -- great follow-up after the array version.",
                         steps: ["left=0, right=n-1, leftMax=0, rightMax=0",
                                  "While left < right: if height[left] < height[right], update leftMax and add trapped water on the left, advance left",
                                  "Otherwise do the symmetric thing on the right"])
            ],
            starterCode: [
                .swift: "func trap(_ height: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def trap(height: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "serialize-deserialize-bst",
            title: "Serialize and Deserialize a Binary Tree",
            difficulty: .hard,
            topics: [.trees],
            companies: [.google, .microsoft, .amazon],
            prompt: "Design an algorithm to serialize a binary tree to a string, and deserialize that string back to the original tree structure.",
            constraints: ["0 ≤ number of nodes ≤ 10^4"],
            examples: [
                Example(input: "[1,2,3,null,null,4,5]", output: "a string encoding that reconstructs the same tree", explanation: nil)
            ],
            hints: [
                "You need to encode enough structural information that nulls are recoverable -- otherwise you can't tell where subtrees end.",
                "A pre-order traversal that explicitly writes a sentinel (like \"#\") for every nil child is reversible.",
                "Deserializing is just replaying that same pre-order recursively: read a token, if it's the sentinel return nil, else build a node and recurse for left then right."
            ],
            approaches: [
                Approach(name: "Pre-order with null sentinels", summary: "Write every node (including explicit nulls) in pre-order; rebuild recursively.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Simplest correct approach -- widely accepted in interviews.",
                         steps: ["serialize: pre-order DFS, append node.val or '#' for nil, comma-separated",
                                  "deserialize: split string, use an index/iterator, recursively consume tokens rebuilding pre-order"]),
                Approach(name: "Level-order (BFS) with sentinels", summary: "Same idea, but breadth-first with an explicit queue.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Alternative if asked to avoid recursion.",
                         steps: ["BFS, writing '#' for nil children too", "Deserialize by rebuilding level by level with a queue"])
            ],
            starterCode: [
                .swift: "final class Codec {\n    func serialize(_ root: TreeNode?) -> String {\n        return \"\"\n    }\n    func deserialize(_ data: String) -> TreeNode? {\n        return nil\n    }\n}\n",
                .python: "class Codec:\n    def serialize(self, root) -> str:\n        return \"\"\n    def deserialize(self, data: str):\n        return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "implement-trie",
            title: "Implement Trie (Prefix Tree)",
            difficulty: .medium,
            topics: [.tries],
            companies: [.google, .amazon, .microsoft, .twitter],
            prompt: "Implement a Trie with `insert(word)`, `search(word)` (exact match), and `startsWith(prefix)` (prefix match).",
            constraints: ["1 ≤ word.length ≤ 2000", "words consist of lowercase English letters"],
            examples: [
                Example(input: "insert(\"apple\"); search(\"apple\")->true; search(\"app\")->false; startsWith(\"app\")->true", output: "see explanation", explanation: nil)
            ],
            hints: [
                "A trie node needs to branch on the next character AND remember whether a word ends there.",
                "Each node can hold a dictionary/array of children keyed by character, plus a boolean 'isEndOfWord' flag.",
                "insert/search/startsWith all just walk character by character, creating nodes (insert) or bailing out early if a character path doesn't exist (search/startsWith)."
            ],
            approaches: [
                Approach(name: "Array/dictionary of child nodes", summary: "Each TrieNode has children keyed by character and an end-of-word flag.",
                         timeComplexity: "O(L) per operation, L = word length", spaceComplexity: "O(total characters inserted)",
                         whenToUse: "This is the standard trie implementation.",
                         steps: ["insert: walk/create nodes per character; mark isEndOfWord on the last one",
                                  "search: walk nodes per character; if any missing, false; else return isEndOfWord",
                                  "startsWith: same walk, but return true as long as the path exists"])
            ],
            starterCode: [
                .swift: "final class Trie {\n    init() {\n        // Write your solution here\n    }\n    func insert(_ word: String) {\n    }\n    func search(_ word: String) -> Bool {\n        return false\n    }\n    func startsWith(_ prefix: String) -> Bool {\n        return false\n    }\n}\n",
                .python: "class Trie:\n    def __init__(self):\n        pass\n    def insert(self, word: str) -> None:\n        pass\n    def search(self, word: str) -> bool:\n        return False\n    def starts_with(self, prefix: str) -> bool:\n        return False\n"
            ],
            followUp: "How would you support wildcard search, where '.' matches any character?"
        ),

        Problem(
            id: "meeting-rooms-ii",
            title: "Meeting Rooms II",
            difficulty: .medium,
            topics: [.intervals, .heaps],
            companies: [.google, .amazon, .microsoft, .uber, .netflix, .linkedin],
            prompt: "Given an array of meeting time intervals `[start, end]`, return the minimum number of conference rooms required so no two meetings overlap in the same room.",
            constraints: ["1 ≤ intervals.count ≤ 10^4"],
            examples: [
                Example(input: "[[0,30],[5,10],[15,20]]", output: "2", explanation: "[5,10] and [15,20] both fit in the second room while [0,30] runs in the first.")
            ],
            hints: [
                "You need to know, at any point in time, how many meetings are simultaneously in progress -- the answer is the peak of that count.",
                "Splitting each interval into a '+1 room' event at start and a '-1 room' event at end, then sweeping through time in order, tracks concurrent meetings directly.",
                "Alternative: a min-heap of currently-occupied rooms' end times -- when a new meeting starts, if the earliest-ending room is already free (end ≤ new start), reuse it; otherwise allocate a new room."
            ],
            approaches: [
                Approach(name: "Sweep line on start/end events", summary: "Sort all start and end times separately; sweep and track the running count.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(n)",
                         whenToUse: "Clean and easy to reason about.",
                         steps: ["starts = sorted start times, ends = sorted end times",
                                  "Two pointers over starts/ends: if starts[i] < ends[j], a room is needed (rooms += 1, i += 1)",
                                  "else a room frees up (i.e. ends[j] ≤ starts[i]): rooms -= 1, j += 1",
                                  "Track the max concurrent rooms seen"]),
                Approach(name: "Min-heap of end times", summary: "Reuse a room if its meeting has already ended by the new meeting's start.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(n)",
                         whenToUse: "Also standard; generalizes well to 'assign an actual room number' follow-ups.",
                         steps: ["Sort meetings by start time", "For each meeting: if heap's smallest end time ≤ this start, pop it (reuse room)",
                                  "Push this meeting's end time", "Answer = max heap size reached"])
            ],
            starterCode: [
                .swift: "func minMeetingRooms(_ intervals: [[Int]]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def min_meeting_rooms(intervals: list[list[int]]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "contains-duplicate",
            title: "Contains Duplicate",
            difficulty: .easy,
            topics: [.arrays],
            companies: [.google, .amazon, .apple],
            prompt: "Given an integer array `nums`, return true if any value appears at least twice in the array.",
            constraints: ["1 ≤ nums.count ≤ 10^5"],
            examples: [
                Example(input: "nums = [1,2,3,1]", output: "true", explanation: nil),
                Example(input: "nums = [1,2,3,4]", output: "false", explanation: nil)
            ],
            hints: [
                "Sorting first lets you check neighbors, but that costs O(n log n) -- can you do it in one pass?",
                "A set lets you check 'have I seen this before?' in O(1) as you scan once."
            ],
            approaches: [
                Approach(name: "Sort and scan", summary: "Sort, then check adjacent equal elements.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(1) or O(n) depending on sort",
                         whenToUse: "Fine, but not the fastest.",
                         steps: ["Sort nums", "Scan adjacent pairs for equality"]),
                Approach(name: "Hash set", summary: "Track seen values; if you see one twice, return true.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Optimal and simplest to write.",
                         steps: ["seen = {}", "For each num: if already in seen, return true; else insert it", "Return false"])
            ],
            starterCode: [
                .swift: "func containsDuplicate(_ nums: [Int]) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def contains_duplicate(nums: list[int]) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "valid-anagram",
            title: "Valid Anagram",
            difficulty: .easy,
            topics: [.arrays],
            companies: [.amazon, .meta],
            prompt: "Given two strings `s` and `t`, return true if `t` is an anagram of `s` (same letters, same counts, any order).",
            constraints: ["1 ≤ s.length, t.length ≤ 5 × 10^4"],
            examples: [
                Example(input: "s = \"anagram\", t = \"nagaram\"", output: "true", explanation: nil),
                Example(input: "s = \"rat\", t = \"car\"", output: "false", explanation: nil)
            ],
            hints: [
                "If the strings have different lengths, they can't be anagrams -- an easy early exit.",
                "Count how many times each character appears in s, then subtract counts as you scan t."
            ],
            approaches: [
                Approach(name: "Sort both strings", summary: "Anagrams sort to the same string.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(n)",
                         whenToUse: "Simple, but not the fastest.",
                         steps: ["Sort s and t", "Compare for equality"]),
                Approach(name: "Character frequency count", summary: "Count characters in s, decrement while scanning t.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1) for a fixed alphabet",
                         whenToUse: "Optimal solution.",
                         steps: ["If lengths differ, return false", "counts[c] += 1 for each c in s",
                                  "counts[c] -= 1 for each c in t", "Return true only if every count is 0"])
            ],
            starterCode: [
                .swift: "func isAnagram(_ s: String, _ t: String) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def is_anagram(s: str, t: str) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: "What if the input contains Unicode characters instead of just lowercase English letters?"
        ),

        Problem(
            id: "missing-number",
            title: "Missing Number",
            difficulty: .easy,
            topics: [.math, .arrays],
            companies: [.microsoft, .amazon],
            prompt: "Given an array `nums` containing `n` distinct numbers from the range `[0, n]`, return the one number missing from the range.",
            constraints: ["1 ≤ n ≤ 10^4"],
            examples: [
                Example(input: "nums = [3,0,1]", output: "2", explanation: "n = 3, range is [0,3], 2 is missing.")
            ],
            hints: [
                "The full range [0, n] has a known sum -- what happens if you subtract the array's actual sum from it?",
                "Alternatively, XOR every index and every value together -- every present number cancels out, leaving the missing one."
            ],
            approaches: [
                Approach(name: "Expected sum minus actual sum", summary: "sum(0..n) - sum(nums) = missing value.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "Simplest, watch for overflow on huge n in other languages.",
                         steps: ["expected = n*(n+1)/2", "actual = sum(nums)", "return expected - actual"]),
                Approach(name: "XOR trick", summary: "XOR all indices 0...n and all values; duplicates cancel, missing remains.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "Avoids any overflow concerns entirely.",
                         steps: ["result = n", "For i in 0..<n: result ^= i ^ nums[i]", "Return result"])
            ],
            starterCode: [
                .swift: "func missingNumber(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def missing_number(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "single-number",
            title: "Single Number",
            difficulty: .easy,
            topics: [.math],
            companies: [.amazon, .apple],
            prompt: "Given a non-empty array where every element appears twice except for one, find the element that appears only once, in O(n) time and O(1) space.",
            constraints: ["1 ≤ nums.count ≤ 3 × 10^4"],
            examples: [
                Example(input: "nums = [4,1,2,1,2]", output: "4", explanation: nil)
            ],
            hints: [
                "A hash map of counts works but costs O(n) space -- the O(1) space requirement is a strong hint toward bit tricks.",
                "XOR-ing a number with itself gives 0, and XOR-ing with 0 gives the number back -- what happens if you XOR the entire array together?"
            ],
            approaches: [
                Approach(name: "XOR fold", summary: "XOR every element together; paired numbers cancel to 0, leaving the single one.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The intended, optimal solution.",
                         steps: ["result = 0", "For each num: result ^= num", "Return result"])
            ],
            starterCode: [
                .swift: "func singleNumber(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def single_number(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "What if every other element appears three times instead of twice?"
        ),

        Problem(
            id: "majority-element",
            title: "Majority Element",
            difficulty: .easy,
            topics: [.arrays],
            companies: [.amazon, .google],
            prompt: "Given an array `nums` of size n, return the majority element -- the value that appears more than ⌊n/2⌋ times. You may assume it always exists.",
            constraints: ["1 ≤ nums.count ≤ 5 × 10^4"],
            examples: [
                Example(input: "nums = [2,2,1,1,1,2,2]", output: "2", explanation: nil)
            ],
            hints: [
                "A hash map of counts works in O(n) time and space -- can you drop the space?",
                "Think of it as a voting game: keep a 'candidate' and a 'count'. When count hits 0, switch candidates.",
                "This is the Boyer-Moore voting algorithm -- because the majority element outnumbers everything else combined, it always survives as the final candidate."
            ],
            approaches: [
                Approach(name: "Hash map counting", summary: "Count occurrences, return the one exceeding n/2.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Straightforward baseline.",
                         steps: ["Count each value", "Return the value with count > n/2"]),
                Approach(name: "Boyer-Moore voting", summary: "Track a candidate and a running count; swap candidate when count reaches 0.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The optimal, expected answer for this problem.",
                         steps: ["candidate = nil, count = 0", "For each num: if count == 0, candidate = num",
                                  "count += (num == candidate) ? 1 : -1", "Return candidate"])
            ],
            starterCode: [
                .swift: "func majorityElement(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def majority_element(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "move-zeroes",
            title: "Move Zeroes",
            difficulty: .easy,
            topics: [.twoPointers, .arrays],
            companies: [.meta, .amazon],
            prompt: "Given an array `nums`, move all 0s to the end while maintaining the relative order of the non-zero elements, in place.",
            constraints: ["1 ≤ nums.count ≤ 10^4"],
            examples: [
                Example(input: "nums = [0,1,0,3,12]", output: "[1,3,12,0,0]", explanation: nil)
            ],
            hints: [
                "You need to preserve relative order, so you can't just sort or freely swap.",
                "Keep a 'write pointer' for the next slot a non-zero value should land in, and walk the array once with a 'read pointer'.",
                "After placing all non-zero values, fill the remaining tail with zeros."
            ],
            approaches: [
                Approach(name: "Two-pointer in-place", summary: "Write non-zero elements forward, then zero-fill the rest.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard optimal in-place solution.",
                         steps: ["writeIndex = 0", "For each num: if non-zero, nums[writeIndex] = num; writeIndex += 1",
                                  "Fill nums[writeIndex...] with 0"])
            ],
            starterCode: [
                .swift: "func moveZeroes(_ nums: inout [Int]) {\n    // Write your solution here\n}\n",
                .python: "def move_zeroes(nums: list[int]) -> None:\n    # Write your solution here, modify nums in place\n    pass\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "palindrome-linked-list",
            title: "Palindrome Linked List",
            difficulty: .easy,
            topics: [.linkedList, .twoPointers],
            companies: [.amazon, .microsoft],
            prompt: "Given the head of a singly linked list, determine whether it reads the same forwards and backwards.",
            constraints: ["1 ≤ number of nodes ≤ 10^5"],
            examples: [
                Example(input: "1 -> 2 -> 2 -> 1", output: "true", explanation: nil),
                Example(input: "1 -> 2", output: "false", explanation: nil)
            ],
            hints: [
                "Copying values into an array makes this trivial but costs O(n) extra space -- can you do it in O(1) space?",
                "Find the middle with slow/fast pointers, then reverse the second half in place.",
                "Compare the first half against the reversed second half node by node."
            ],
            approaches: [
                Approach(name: "Copy to array", summary: "Dump values into an array, then check it's a palindrome.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Simple and fine unless O(1) space is required.",
                         steps: ["Walk the list collecting values", "Two-pointer check from both ends of the array"]),
                Approach(name: "Reverse second half in place", summary: "Find the middle, reverse the back half, compare halves.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The optimal, expected approach.",
                         steps: ["Slow/fast pointers to find the middle", "Reverse the second half of the list",
                                  "Walk both halves simultaneously comparing values", "(Optional) restore the list by reversing back"])
            ],
            starterCode: [
                .swift: "func isPalindrome(_ head: ListNode?) -> Bool {\n    // Write your solution here\n    return true\n}\n",
                .python: "def is_palindrome(head) -> bool:\n    # Write your solution here\n    return True\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "merge-two-sorted-lists",
            title: "Merge Two Sorted Lists",
            difficulty: .easy,
            topics: [.linkedList],
            companies: [.amazon, .microsoft, .apple],
            prompt: "Merge two sorted linked lists into one sorted list by splicing their nodes together, and return the head of the merged list.",
            constraints: ["0 ≤ number of nodes in each list ≤ 50"],
            examples: [
                Example(input: "l1 = 1->2->4, l2 = 1->3->4", output: "1->1->2->3->4->4", explanation: nil)
            ],
            hints: [
                "A dummy head node avoids annoying special-casing for 'what's the new head?'.",
                "At each step, compare the two current nodes and attach the smaller one, then advance only that list's pointer.",
                "Once one list runs out, attach the rest of the other list directly -- it's already sorted."
            ],
            approaches: [
                Approach(name: "Iterative merge with a dummy head", summary: "Splice nodes onto a dummy list, always taking the smaller current node.",
                         timeComplexity: "O(n + m)", spaceComplexity: "O(1)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["dummy = ListNode(); tail = dummy", "While both lists non-empty: attach smaller node, advance",
                                  "Attach whichever list remains", "Return dummy.next"])
            ],
            starterCode: [
                .swift: "func mergeTwoLists(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def merge_two_lists(l1, l2):\n    # Write your solution here\n    return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "symmetric-tree",
            title: "Symmetric Tree",
            difficulty: .easy,
            topics: [.trees],
            companies: [.microsoft, .amazon],
            prompt: "Given the root of a binary tree, check whether it is a mirror of itself (symmetric around its center).",
            constraints: ["1 ≤ number of nodes ≤ 1000"],
            examples: [
                Example(input: "[1,2,2,3,4,4,3]", output: "true", explanation: nil),
                Example(input: "[1,2,2,null,3,null,3]", output: "false", explanation: nil)
            ],
            hints: [
                "Symmetry means the left subtree mirrors the right subtree -- that's a relationship between *two* trees, not one.",
                "Write a helper that checks whether two subtrees are mirrors: their root values match, left of one mirrors right of the other, and vice versa."
            ],
            approaches: [
                Approach(name: "Recursive mirror check", summary: "Compare left/right subtrees pairwise, cross-checking children.",
                         timeComplexity: "O(n)", spaceComplexity: "O(h) recursion stack",
                         whenToUse: "Simplest, expected solution.",
                         steps: ["isMirror(a, b): both nil -> true; one nil -> false",
                                  "a.val == b.val && isMirror(a.left, b.right) && isMirror(a.right, b.left)",
                                  "Call isMirror(root.left, root.right)"])
            ],
            starterCode: [
                .swift: "func isSymmetric(_ root: TreeNode?) -> Bool {\n    // Write your solution here\n    return true\n}\n",
                .python: "def is_symmetric(root) -> bool:\n    # Write your solution here\n    return True\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "maximum-depth-binary-tree",
            title: "Maximum Depth of Binary Tree",
            difficulty: .easy,
            topics: [.trees],
            companies: [.amazon, .linkedin],
            prompt: "Given the root of a binary tree, return its maximum depth (the number of nodes along the longest path from root to a leaf).",
            constraints: ["0 ≤ number of nodes ≤ 10^4"],
            examples: [
                Example(input: "[3,9,20,null,null,15,7]", output: "3", explanation: nil)
            ],
            hints: [
                "The depth of a tree is 1 (for the root) plus the deeper of its two subtrees' depths.",
                "This recurrence bottoms out cleanly: an empty tree has depth 0."
            ],
            approaches: [
                Approach(name: "Recursive", summary: "depth(node) = 1 + max(depth(left), depth(right)).",
                         timeComplexity: "O(n)", spaceComplexity: "O(h) recursion stack",
                         whenToUse: "Simplest and most common.",
                         steps: ["If node is nil, return 0", "Return 1 + max(depth(node.left), depth(node.right))"]),
                Approach(name: "Iterative BFS level counting", summary: "Count how many levels a level-order traversal produces.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "Good alternative if asked to avoid recursion.",
                         steps: ["BFS with a queue, incrementing a depth counter once per full level"])
            ],
            starterCode: [
                .swift: "func maxDepth(_ root: TreeNode?) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def max_depth(root) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "diameter-of-binary-tree",
            title: "Diameter of Binary Tree",
            difficulty: .easy,
            topics: [.trees],
            companies: [.google, .meta],
            prompt: "Given the root of a binary tree, return the length (in edges) of the longest path between any two nodes -- the path does not need to pass through the root.",
            constraints: ["1 ≤ number of nodes ≤ 10^4"],
            examples: [
                Example(input: "[1,2,3,4,5]", output: "3", explanation: "The longest path is 4 -> 2 -> 1 -> 3 (or 5 -> 2 -> 1 -> 3), 3 edges.")
            ],
            hints: [
                "The longest path *through* any given node equals the height of its left subtree plus the height of its right subtree.",
                "You need the best answer over *all* nodes, not just the root -- so track a running global maximum while you compute heights.",
                "One recursive pass can both compute height and update the global diameter as a side effect."
            ],
            approaches: [
                Approach(name: "Height recursion with a running max", summary: "Compute height bottom-up; at each node, update diameter = max(diameter, leftHeight + rightHeight).",
                         timeComplexity: "O(n)", spaceComplexity: "O(h) recursion stack",
                         whenToUse: "The standard, efficient solution -- avoids recomputing heights repeatedly.",
                         steps: ["height(node): if nil return 0", "l = height(node.left), r = height(node.right)",
                                  "diameter = max(diameter, l + r)", "return 1 + max(l, r)"])
            ],
            starterCode: [
                .swift: "func diameterOfBinaryTree(_ root: TreeNode?) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def diameter_of_binary_tree(root) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "search-insert-position",
            title: "Search Insert Position",
            difficulty: .easy,
            topics: [.binarySearch],
            companies: [.google, .microsoft],
            prompt: "Given a sorted array of distinct integers `nums` and a target value, return the index if found, or the index where it would be inserted to keep the array sorted.",
            constraints: ["1 ≤ nums.count ≤ 10^4", "nums is sorted in ascending order with distinct values"],
            examples: [
                Example(input: "nums = [1,3,5,6], target = 5", output: "2", explanation: nil),
                Example(input: "nums = [1,3,5,6], target = 2", output: "1", explanation: nil)
            ],
            hints: [
                "A linear scan works but is O(n) -- the sorted array is a strong hint for binary search, O(log n).",
                "Standard binary search: when the loop ends without finding the target, `left` naturally lands on the correct insertion index."
            ],
            approaches: [
                Approach(name: "Binary search", summary: "Standard binary search; on failure, `left` is the insertion point.",
                         timeComplexity: "O(log n)", spaceComplexity: "O(1)",
                         whenToUse: "The expected optimal solution.",
                         steps: ["left = 0, right = n - 1", "While left ≤ right: mid = (left+right)/2; compare and narrow",
                                  "Return left when the loop ends"])
            ],
            starterCode: [
                .swift: "func searchInsert(_ nums: [Int], _ target: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def search_insert(nums: list[int], target: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "3sum",
            title: "3Sum",
            difficulty: .medium,
            topics: [.twoPointers, .arrays],
            companies: [.amazon, .meta, .microsoft],
            prompt: "Given an integer array `nums`, return all unique triplets `[nums[i], nums[j], nums[k]]` that sum to zero. The result must not contain duplicate triplets.",
            constraints: ["3 ≤ nums.count ≤ 3000"],
            examples: [
                Example(input: "nums = [-1,0,1,2,-1,-4]", output: "[[-1,-1,2],[-1,0,1]]", explanation: nil)
            ],
            hints: [
                "Brute force over all triplets is O(n³) -- sorting first opens up a much better strategy.",
                "Fix one number, then find two others that sum to its negation using the two-pointer technique on the (sorted) rest of the array.",
                "Skip over duplicate values at each position to avoid emitting the same triplet twice."
            ],
            approaches: [
                Approach(name: "Sort + fix one + two pointers", summary: "Sort the array; for each index, two-pointer search the remainder for a complementary pair.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(log n) to O(n) for the sort",
                         whenToUse: "The standard optimal approach for 3Sum.",
                         steps: ["Sort nums", "For each i (skipping duplicates): left = i+1, right = n-1",
                                  "While left < right: if sum == 0, record triplet and skip duplicates; else move left/right based on sum vs 0"])
            ],
            starterCode: [
                .swift: "func threeSum(_ nums: [Int]) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def three_sum(nums: list[int]) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: "How would you extend this approach to 4Sum?"
        ),

        Problem(
            id: "group-anagrams",
            title: "Group Anagrams",
            difficulty: .medium,
            topics: [.arrays],
            companies: [.amazon, .uber],
            prompt: "Given an array of strings, group the anagrams together. You can return the answer in any order.",
            constraints: ["1 ≤ strs.count ≤ 10^4", "0 ≤ strs[i].length ≤ 100"],
            examples: [
                Example(input: "strs = [\"eat\",\"tea\",\"tan\",\"ate\",\"nat\",\"bat\"]",
                        output: "[[\"bat\"],[\"nat\",\"tan\"],[\"ate\",\"eat\",\"tea\"]]", explanation: nil)
            ],
            hints: [
                "Anagrams share the same multiset of letters -- what value could you compute that's identical for every anagram of a word, but different otherwise?",
                "A sorted version of the string (or a 26-count signature) works as a grouping key.",
                "A hash map from key -> list of original strings groups everything in one pass."
            ],
            approaches: [
                Approach(name: "Sorted-string key", summary: "Group strings by their sorted-character signature.",
                         timeComplexity: "O(n · k log k), k = max string length", spaceComplexity: "O(n · k)",
                         whenToUse: "Simple and usually fast enough.",
                         steps: ["For each string, compute sortedKey = sorted characters joined",
                                  "groups[sortedKey].append(originalString)", "Return groups.values"]),
                Approach(name: "Character-count key", summary: "Group by a 26-length count array instead of sorting.",
                         timeComplexity: "O(n · k)", spaceComplexity: "O(n · k)",
                         whenToUse: "Avoids the log k sort factor -- faster for long strings.",
                         steps: ["For each string, build a 26-length count array as the key",
                                  "groups[countKey].append(originalString)"])
            ],
            starterCode: [
                .swift: "func groupAnagrams(_ strs: [String]) -> [[String]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def group_anagrams(strs: list[str]) -> list[list[str]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "container-with-most-water",
            title: "Container With Most Water",
            difficulty: .medium,
            topics: [.twoPointers, .arrays],
            companies: [.google, .amazon],
            prompt: "Given `n` non-negative integers representing vertical line heights at each position, find two lines that, together with the x-axis, form a container holding the most water.",
            constraints: ["2 ≤ height.count ≤ 10^5"],
            examples: [
                Example(input: "height = [1,8,6,2,5,4,8,3,7]", output: "49", explanation: "Lines at index 1 (height 8) and index 8 (height 7): width 7 × min(8,7) = 49.")
            ],
            hints: [
                "Checking every pair is O(n²) -- start with the widest possible container (both ends) and think about when narrowing helps.",
                "The container's height is limited by the *shorter* of the two lines -- so moving the taller line inward can never help, only moving the shorter one can.",
                "Two pointers from both ends, always advancing the shorter side, explores the useful search space in O(n)."
            ],
            approaches: [
                Approach(name: "Brute force", summary: "Check every pair of lines.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(1)",
                         whenToUse: "For intuition only.",
                         steps: ["Nested loop over all (i, j) pairs", "Track max(min(height[i],height[j]) * (j - i))"]),
                Approach(name: "Two pointers, move the shorter side", summary: "Start at both ends; always move the pointer at the shorter line inward.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The optimal, expected solution.",
                         steps: ["left = 0, right = n-1, best = 0", "While left < right: best = max(best, area)",
                                  "Move whichever pointer points at the shorter line"])
            ],
            starterCode: [
                .swift: "func maxArea(_ height: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def max_area(height: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "rotate-image",
            title: "Rotate Image",
            difficulty: .medium,
            topics: [.arrays, .math],
            companies: [.amazon, .microsoft],
            prompt: "You're given an `n x n` 2D matrix representing an image. Rotate the image by 90 degrees clockwise, in place.",
            constraints: ["1 ≤ n ≤ 20"],
            examples: [
                Example(input: "[[1,2,3],[4,5,6],[7,8,9]]", output: "[[7,4,1],[8,5,2],[9,6,3]]", explanation: nil)
            ],
            hints: [
                "Doing it 'in place' rules out simply allocating a new rotated matrix.",
                "A 90-degree clockwise rotation is the same as: transpose the matrix, then reverse each row.",
                "Transposing swaps matrix[i][j] with matrix[j][i]; make sure you only do it for one triangle to avoid swapping twice."
            ],
            approaches: [
                Approach(name: "Transpose then reverse rows", summary: "Transpose in place, then reverse each row.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(1)",
                         whenToUse: "The cleanest in-place approach.",
                         steps: ["For i < j: swap matrix[i][j] and matrix[j][i] (transpose)",
                                  "Reverse each row in place"])
            ],
            starterCode: [
                .swift: "func rotate(_ matrix: inout [[Int]]) {\n    // Write your solution here\n}\n",
                .python: "def rotate(matrix: list[list[int]]) -> None:\n    # Write your solution here, modify matrix in place\n    pass\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "spiral-matrix",
            title: "Spiral Matrix",
            difficulty: .medium,
            topics: [.arrays],
            companies: [.amazon, .microsoft, .google],
            prompt: "Given an `m x n` matrix, return all elements in spiral order (clockwise, from the outside in).",
            constraints: ["1 ≤ m, n ≤ 10"],
            examples: [
                Example(input: "[[1,2,3],[4,5,6],[7,8,9]]", output: "[1,2,3,6,9,8,7,4,5]", explanation: nil)
            ],
            hints: [
                "Track four shrinking boundaries: top, bottom, left, right.",
                "Walk right along the top row, down the right column, left along the bottom row, up the left column -- then shrink each boundary inward and repeat.",
                "Be careful with the final partial row/column when the matrix isn't square -- check bounds before each leg."
            ],
            approaches: [
                Approach(name: "Shrinking boundary walk", summary: "Peel off the outer ring layer by layer, adjusting four boundary pointers.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(1) extra (excluding output)",
                         whenToUse: "The standard, expected approach.",
                         steps: ["top=0, bottom=m-1, left=0, right=n-1",
                                  "While top ≤ bottom && left ≤ right: walk right along top, down along right, left along bottom (if top≠bottom), up along left (if left≠right)",
                                  "Shrink all four boundaries inward by 1 after each ring"])
            ],
            starterCode: [
                .swift: "func spiralOrder(_ matrix: [[Int]]) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def spiral_order(matrix: list[list[int]]) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "set-matrix-zeroes",
            title: "Set Matrix Zeroes",
            difficulty: .medium,
            topics: [.arrays],
            companies: [.amazon, .microsoft],
            prompt: "Given an `m x n` matrix, if an element is 0, set its entire row and column to 0, in place.",
            constraints: ["1 ≤ m, n ≤ 200"],
            examples: [
                Example(input: "[[1,1,1],[1,0,1],[1,1,1]]", output: "[[1,0,1],[0,0,0],[1,0,1]]", explanation: nil)
            ],
            hints: [
                "If you zero cells as you find them, you'll accidentally treat newly-zeroed cells as 'original' zeros later -- you need to record positions first.",
                "A separate set of 'rows to zero' and 'columns to zero' works in O(m+n) extra space -- can you do it in O(1) extra space?",
                "Use the first row and first column of the matrix itself as the markers, with one extra flag for whether the first row/column originally had a zero."
            ],
            approaches: [
                Approach(name: "Record then zero", summary: "First pass records which rows/cols contain a zero; second pass zeroes them.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(m + n)",
                         whenToUse: "Simple and clear -- good first answer.",
                         steps: ["Scan matrix, recording zero rows/cols in sets", "Second pass: zero any cell whose row or col is marked"]),
                Approach(name: "In-place markers using row 0 / col 0", summary: "Use the matrix's own first row/column as marker space.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(1)",
                         whenToUse: "The fully optimal follow-up.",
                         steps: ["Track separately whether row 0 / col 0 themselves need zeroing",
                                  "For other cells that are 0, mark matrix[i][0] = 0 and matrix[0][j] = 0",
                                  "Second pass (excluding row 0/col 0): zero cells whose marker is 0",
                                  "Finally zero row 0 / col 0 themselves if flagged"])
            ],
            starterCode: [
                .swift: "func setZeroes(_ matrix: inout [[Int]]) {\n    // Write your solution here\n}\n",
                .python: "def set_zeroes(matrix: list[list[int]]) -> None:\n    # Write your solution here, modify matrix in place\n    pass\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "search-rotated-sorted-array",
            title: "Search in Rotated Sorted Array",
            difficulty: .medium,
            topics: [.binarySearch],
            companies: [.amazon, .google, .microsoft],
            prompt: "You're given a sorted array that has been rotated at an unknown pivot. Given a target value, return its index, or -1 if not present, in O(log n) time.",
            constraints: ["1 ≤ nums.count ≤ 5000", "All values are distinct"],
            examples: [
                Example(input: "nums = [4,5,6,7,0,1,2], target = 0", output: "4", explanation: nil),
                Example(input: "nums = [4,5,6,7,0,1,2], target = 3", output: "-1", explanation: nil)
            ],
            hints: [
                "The array isn't fully sorted, but at least one half of any given subrange always IS sorted -- that's the key insight.",
                "At each step of binary search, figure out which half (left of mid, or right of mid) is the sorted one by comparing endpoints.",
                "Once you know which half is sorted, it's easy to check whether the target could be in that sorted half's range; narrow accordingly."
            ],
            approaches: [
                Approach(name: "Modified binary search", summary: "At each step, determine which half is sorted and decide which half to search.",
                         timeComplexity: "O(log n)", spaceComplexity: "O(1)",
                         whenToUse: "The expected, optimal solution.",
                         steps: ["left=0, right=n-1", "mid = (left+right)/2; if nums[mid]==target, return mid",
                                  "If nums[left] ≤ nums[mid]: left half is sorted -- check if target is in [nums[left], nums[mid])",
                                  "Else right half is sorted -- check if target is in (nums[mid], nums[right]]",
                                  "Narrow left/right accordingly"])
            ],
            starterCode: [
                .swift: "func search(_ nums: [Int], _ target: Int) -> Int {\n    // Write your solution here\n    return -1\n}\n",
                .python: "def search(nums: list[int], target: int) -> int:\n    # Write your solution here\n    return -1\n"
            ],
            followUp: "What changes if the array can contain duplicate values?"
        ),

        Problem(
            id: "find-minimum-rotated-sorted-array",
            title: "Find Minimum in Rotated Sorted Array",
            difficulty: .medium,
            topics: [.binarySearch],
            companies: [.amazon],
            prompt: "Given a sorted array rotated at an unknown pivot with all distinct values, find the minimum element in O(log n) time.",
            constraints: ["1 ≤ nums.count ≤ 5000"],
            examples: [
                Example(input: "nums = [3,4,5,1,2]", output: "1", explanation: nil)
            ],
            hints: [
                "Compare the middle element to the rightmost element -- that tells you which half contains the rotation point (and therefore the minimum).",
                "If nums[mid] > nums[right], the minimum is somewhere to the right of mid; otherwise it's at mid or to its left."
            ],
            approaches: [
                Approach(name: "Binary search on the rotation point", summary: "Compare mid to right to decide which half holds the minimum.",
                         timeComplexity: "O(log n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard optimal solution.",
                         steps: ["left=0, right=n-1", "While left < right: mid = (left+right)/2",
                                  "If nums[mid] > nums[right]: left = mid + 1", "Else: right = mid",
                                  "Return nums[left]"])
            ],
            starterCode: [
                .swift: "func findMin(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def find_min(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "daily-temperatures",
            title: "Daily Temperatures",
            difficulty: .medium,
            topics: [.stack],
            companies: [.amazon, .google],
            prompt: "Given an array of daily temperatures, return an array where `answer[i]` is the number of days until a warmer temperature; 0 if there isn't a future warmer day.",
            constraints: ["1 ≤ temperatures.count ≤ 10^5"],
            examples: [
                Example(input: "temperatures = [73,74,75,71,69,72,76,73]", output: "[1,1,4,2,1,1,0,0]", explanation: nil)
            ],
            hints: [
                "Comparing every day to every future day is O(n²) -- can you resolve each day's answer as soon as a warmer day appears?",
                "Keep a stack of indices whose 'warmer day' hasn't been found yet. When you see a new temperature, it might resolve several of them at once.",
                "While the stack's top index has a colder temperature than the current day, pop it and record the day-distance."
            ],
            approaches: [
                Approach(name: "Monotonic decreasing stack", summary: "Maintain a stack of unresolved indices with decreasing temperatures.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard optimal approach for 'next greater element' style problems.",
                         steps: ["stack = [] (indices)", "For i, temp in temperatures: while stack not empty and temp > temperatures[stack.top]: j = stack.pop(); answer[j] = i - j",
                                  "Push i onto the stack"])
            ],
            starterCode: [
                .swift: "func dailyTemperatures(_ temperatures: [Int]) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def daily_temperatures(temperatures: list[int]) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "evaluate-reverse-polish-notation",
            title: "Evaluate Reverse Polish Notation",
            difficulty: .medium,
            topics: [.stack],
            companies: [.amazon, .linkedin],
            prompt: "Evaluate an arithmetic expression given in Reverse Polish (postfix) Notation, where tokens are either integers or one of `+ - * /`.",
            constraints: ["1 ≤ tokens.count ≤ 10^4"],
            examples: [
                Example(input: "tokens = [\"2\",\"1\",\"+\",\"3\",\"*\"]", output: "9", explanation: "(2 + 1) * 3 = 9")
            ],
            hints: [
                "Postfix notation is exactly what a stack-based evaluator is built for.",
                "Push numbers onto a stack. When you hit an operator, pop the two most recent numbers, apply the operator, and push the result back."
            ],
            approaches: [
                Approach(name: "Stack-based evaluation", summary: "Push numbers, apply operators to the top two stack values.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The direct, standard solution.",
                         steps: ["For each token: if it's a number, push it",
                                  "If it's an operator, pop b then a, push (a operator b)",
                                  "Return the single remaining stack value"])
            ],
            starterCode: [
                .swift: "func evalRPN(_ tokens: [String]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def eval_rpn(tokens: list[str]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "generate-parentheses",
            title: "Generate Parentheses",
            difficulty: .medium,
            topics: [.backtracking],
            companies: [.amazon, .meta, .google],
            prompt: "Given `n` pairs of parentheses, generate all combinations of well-formed parentheses strings.",
            constraints: ["1 ≤ n ≤ 8"],
            examples: [
                Example(input: "n = 3", output: "[\"((()))\",\"(()())\",\"(())()\",\"()(())\",\"()()()\"]", explanation: nil)
            ],
            hints: [
                "At each position you have (up to) two choices: add '(' or add ')' -- but not every choice keeps the string valid.",
                "You can add '(' as long as you haven't used all n yet. You can only add ')' if it wouldn't outnumber the '(' used so far.",
                "Backtrack: try a choice, recurse, then undo it and try the other."
            ],
            approaches: [
                Approach(name: "Backtracking with open/close counters", summary: "Track how many '(' and ')' have been used; only recurse into valid next characters.",
                         timeComplexity: "O(4^n / sqrt(n)) (Catalan-bounded)", spaceComplexity: "O(n) recursion depth",
                         whenToUse: "The standard, expected solution.",
                         steps: ["backtrack(current, openCount, closeCount)",
                                  "If openCount < n: recurse with current + '(' and openCount+1",
                                  "If closeCount < openCount: recurse with current + ')' and closeCount+1",
                                  "If current.length == 2n: record it"])
            ],
            starterCode: [
                .swift: "func generateParenthesis(_ n: Int) -> [String] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def generate_parenthesis(n: int) -> list[str]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "subsets",
            title: "Subsets",
            difficulty: .medium,
            topics: [.backtracking],
            companies: [.amazon, .meta],
            prompt: "Given an integer array of unique elements, return all possible subsets (the power set).",
            constraints: ["1 ≤ nums.count ≤ 10"],
            examples: [
                Example(input: "nums = [1,2,3]", output: "[[],[1],[2],[1,2],[3],[1,3],[2,3],[1,2,3]]", explanation: nil)
            ],
            hints: [
                "Every element is either in a given subset or it isn't -- that binary choice, made for every element, is a natural backtracking tree.",
                "At each index, branch into two recursive calls: one including nums[i] in the current subset, one excluding it."
            ],
            approaches: [
                Approach(name: "Backtracking (include/exclude)", summary: "At each index, branch on including or excluding the element.",
                         timeComplexity: "O(n · 2^n)", spaceComplexity: "O(n) recursion depth",
                         whenToUse: "Clean and intuitive.",
                         steps: ["backtrack(index, current)", "If index == n: record a copy of current",
                                  "current.append(nums[index]); backtrack(index+1, current); current.removeLast() -- include branch",
                                  "backtrack(index+1, current) -- exclude branch"]),
                Approach(name: "Iterative doubling", summary: "Start with [[]], and for each number, duplicate all existing subsets with that number added.",
                         timeComplexity: "O(n · 2^n)", spaceComplexity: "O(n · 2^n)",
                         whenToUse: "Elegant non-recursive alternative.",
                         steps: ["result = [[]]", "For each num: result += [subset + [num] for subset in result]"])
            ],
            starterCode: [
                .swift: "func subsets(_ nums: [Int]) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def subsets(nums: list[int]) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "permutations",
            title: "Permutations",
            difficulty: .medium,
            topics: [.backtracking],
            companies: [.amazon, .microsoft],
            prompt: "Given an array of distinct integers, return all possible permutations, in any order.",
            constraints: ["1 ≤ nums.count ≤ 6"],
            examples: [
                Example(input: "nums = [1,2,3]", output: "[[1,2,3],[1,3,2],[2,1,3],[2,3,1],[3,1,2],[3,2,1]]", explanation: nil)
            ],
            hints: [
                "At each position of the permutation, you can place any number that hasn't been used yet.",
                "Track which numbers are 'used' so far; backtrack by un-marking a number after exploring it."
            ],
            approaches: [
                Approach(name: "Backtracking with a used-set", summary: "Build permutations position by position, skipping already-used numbers.",
                         timeComplexity: "O(n · n!)", spaceComplexity: "O(n) recursion depth",
                         whenToUse: "The standard approach.",
                         steps: ["backtrack(current, used)", "If current.length == n: record a copy",
                                  "For each num not in used: mark used, append to current, recurse, then backtrack (unmark, remove)"])
            ],
            starterCode: [
                .swift: "func permute(_ nums: [Int]) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def permute(nums: list[int]) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "combination-sum",
            title: "Combination Sum",
            difficulty: .medium,
            topics: [.backtracking],
            companies: [.amazon, .uber],
            prompt: "Given an array of distinct positive integers `candidates` and a target, return all unique combinations where the chosen numbers sum to target. The same number may be reused unlimited times.",
            constraints: ["1 ≤ candidates.count ≤ 30", "1 ≤ target ≤ 40"],
            examples: [
                Example(input: "candidates = [2,3,6,7], target = 7", output: "[[2,2,3],[7]]", explanation: nil)
            ],
            hints: [
                "Since numbers can repeat, at each step you can either reuse the current candidate again or move to the next one -- but never go backwards, or you'll get duplicate combinations.",
                "Prune early: if the running sum exceeds target, stop exploring that branch (sorting candidates first makes this pruning effective)."
            ],
            approaches: [
                Approach(name: "Backtracking with a start index", summary: "Recurse allowing the same index to repeat, but never revisiting earlier indices.",
                         timeComplexity: "Exponential, bounded by target/min(candidate)", spaceComplexity: "O(target) recursion depth",
                         whenToUse: "The standard approach for 'combinations summing to target with reuse allowed'.",
                         steps: ["backtrack(startIndex, remaining, current)", "If remaining == 0: record current",
                                  "If remaining < 0: return (prune)",
                                  "For i from startIndex to n-1: append candidates[i], backtrack(i, remaining - candidates[i], current), then remove"])
            ],
            starterCode: [
                .swift: "func combinationSum(_ candidates: [Int], _ target: Int) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def combination_sum(candidates: list[int], target: int) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: "How would this change if each candidate could only be used once?"
        ),

        Problem(
            id: "clone-graph",
            title: "Clone Graph",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.meta, .google],
            prompt: "Given a reference to a node in a connected undirected graph, return a deep copy (clone) of the entire graph.",
            constraints: ["0 ≤ number of nodes ≤ 100"],
            examples: [
                Example(input: "adjList = [[2,4],[1,3],[2,4],[1,3]]", output: "a structurally identical, fully independent copy", explanation: nil)
            ],
            hints: [
                "Since the graph can have cycles, a naive recursive clone would loop forever -- you need to remember nodes you've already cloned.",
                "A map from original node -> cloned node lets you detect 'already cloned this one' and reuse the clone instead of infinitely recursing.",
                "DFS or BFS both work: visit a node, clone it, then recursively (or iteratively) clone its neighbors, wiring up the map as you go."
            ],
            approaches: [
                Approach(name: "DFS with a clone map", summary: "Recursively clone, using a map to avoid re-cloning or infinite loops on cycles.",
                         timeComplexity: "O(V + E)", spaceComplexity: "O(V)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["clone(node): if node in map, return map[node]",
                                  "Create copy, store in map[node] = copy BEFORE recursing (breaks cycles)",
                                  "For each neighbor: copy.neighbors.append(clone(neighbor))", "Return copy"])
            ],
            starterCode: [
                .swift: "// class Node { var val: Int; var neighbors: [Node] = []; init(_ v: Int) { val = v } }\nfunc cloneGraph(_ node: Node?) -> Node? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def clone_graph(node):\n    # Write your solution here\n    return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "pacific-atlantic-water-flow",
            title: "Pacific Atlantic Water Flow",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.amazon, .google],
            prompt: "Given an `m x n` grid of heights representing an island bordered by the Pacific (top/left edges) and Atlantic (bottom/right edges) oceans, return all cells from which water can flow to both oceans (water flows from a cell to an adjacent cell with height ≤ current).",
            constraints: ["1 ≤ m, n ≤ 200"],
            examples: [
                Example(input: "heights grid (see problem)", output: "list of [row, col] cells that reach both oceans", explanation: nil)
            ],
            hints: [
                "Checking 'can this cell reach the Pacific?' by simulating flow forward from every cell is O((mn)²) -- too slow.",
                "Flip the problem: instead of asking 'where can water flow FROM this cell', do a reverse flood-fill FROM each ocean's border, moving to neighbors that are ≥ current height (i.e. water could have flowed down to here).",
                "Run one flood-fill from all Pacific-border cells and one from all Atlantic-border cells; the answer is cells reachable in both."
            ],
            approaches: [
                Approach(name: "Reverse multi-source flood fill", summary: "Flood-fill inward from each ocean's border cells; intersect the two reachable sets.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(m·n)",
                         whenToUse: "The standard, efficient approach.",
                         steps: ["pacificReachable = flood-fill from all top-row and left-column cells, moving to neighbors with height ≥ current",
                                  "atlanticReachable = same, from bottom-row and right-column cells",
                                  "Return cells in both sets"])
            ],
            starterCode: [
                .swift: "func pacificAtlantic(_ heights: [[Int]]) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def pacific_atlantic(heights: list[list[int]]) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "rotting-oranges",
            title: "Rotting Oranges",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.amazon, .google],
            prompt: "Given a grid where each cell is 0 (empty), 1 (fresh orange), or 2 (rotten orange), every minute a rotten orange rots any adjacent fresh orange. Return the minimum minutes until no fresh orange remains, or -1 if impossible.",
            constraints: ["1 ≤ rows, cols ≤ 10"],
            examples: [
                Example(input: "[[2,1,1],[1,1,0],[0,1,1]]", output: "4", explanation: nil)
            ],
            hints: [
                "Rot spreads outward simultaneously from every rotten orange at once, one 'ring' per minute -- that's exactly what multi-source BFS models.",
                "Start a BFS queue with ALL initially-rotten oranges at once (minute 0), not just one -- then expand level by level, counting minutes.",
                "After the BFS, check if any fresh orange is still unreached -- that means -1."
            ],
            approaches: [
                Approach(name: "Multi-source BFS", summary: "Enqueue all rotten oranges at once; BFS level by level counts elapsed minutes.",
                         timeComplexity: "O(rows · cols)", spaceComplexity: "O(rows · cols)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["queue = all initially rotten cells; count fresh oranges",
                                  "BFS level by level: each level = 1 minute; rot adjacent fresh oranges, decrement fresh count",
                                  "After BFS, return minutes if fresh count == 0, else -1"])
            ],
            starterCode: [
                .swift: "func orangesRotting(_ grid: [[Int]]) -> Int {\n    // Write your solution here\n    return -1\n}\n",
                .python: "def oranges_rotting(grid: list[list[int]]) -> int:\n    # Write your solution here\n    return -1\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "longest-increasing-subsequence",
            title: "Longest Increasing Subsequence",
            difficulty: .medium,
            topics: [.dynamicProgramming, .binarySearch],
            companies: [.google, .microsoft, .meta],
            prompt: "Given an integer array `nums`, return the length of the longest strictly increasing subsequence (elements don't need to be contiguous).",
            constraints: ["1 ≤ nums.count ≤ 2500"],
            examples: [
                Example(input: "nums = [10,9,2,5,3,7,101,18]", output: "4", explanation: "[2,3,7,101] or [2,3,7,18]")
            ],
            hints: [
                "Define dp[i] = length of the longest increasing subsequence ending exactly at index i.",
                "dp[i] = 1 + max(dp[j]) over all j < i where nums[j] < nums[i] -- that gives an O(n²) solution.",
                "For O(n log n): maintain an array of 'smallest tail value for each achievable subsequence length', and binary-search where each new number fits."
            ],
            approaches: [
                Approach(name: "DP, O(n²)", summary: "dp[i] = 1 + best dp[j] for any earlier smaller element.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(n)",
                         whenToUse: "Straightforward and usually accepted first.",
                         steps: ["dp = array of 1s", "For i in 0..<n: for j in 0..<i: if nums[j] < nums[i]: dp[i] = max(dp[i], dp[j] + 1)",
                                  "Return max(dp)"]),
                Approach(name: "Patience sorting with binary search", summary: "Maintain smallest possible tail for each subsequence length; binary search + replace.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(n)",
                         whenToUse: "The optimal approach -- strong follow-up answer.",
                         steps: ["tails = []", "For each num: binary search tails for the first value ≥ num",
                                  "If found, replace it with num; if not found, append num",
                                  "Return tails.count"])
            ],
            starterCode: [
                .swift: "func lengthOfLIS(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def length_of_lis(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "Can you reconstruct the actual subsequence, not just its length?"
        ),

        Problem(
            id: "word-break",
            title: "Word Break",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.amazon, .google, .meta],
            prompt: "Given a string `s` and a dictionary of strings `wordDict`, return true if `s` can be segmented into a space-separated sequence of one or more dictionary words. Words may be reused.",
            constraints: ["1 ≤ s.length ≤ 300", "1 ≤ wordDict.count ≤ 1000"],
            examples: [
                Example(input: "s = \"leetcode\", wordDict = [\"leet\",\"code\"]", output: "true", explanation: nil),
                Example(input: "s = \"catsandog\", wordDict = [\"cats\",\"dog\",\"sand\",\"and\",\"cat\"]", output: "false", explanation: nil)
            ],
            hints: [
                "Trying every way to split the string recursively re-explores the same sub-strings repeatedly -- a classic sign that DP/memoization helps.",
                "Define dp[i] = 'can s[0..<i] be segmented using dictionary words?'. dp[0] = true (empty prefix).",
                "dp[i] is true if there's some j < i where dp[j] is true AND s[j..<i] is in the dictionary."
            ],
            approaches: [
                Approach(name: "Bottom-up DP", summary: "dp[i] = true if some earlier valid split point j has s[j..<i] as a dictionary word.",
                         timeComplexity: "O(n² ) plus dictionary lookups", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["dp = array of n+1 falses; dp[0] = true",
                                  "For i in 1...n: for j in 0..<i: if dp[j] && wordSet.contains(s[j..<i]): dp[i] = true; break",
                                  "Return dp[n]"])
            ],
            starterCode: [
                .swift: "func wordBreak(_ s: String, _ wordDict: [String]) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def word_break(s: str, word_dict: list[str]) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: "Can you return every possible way to segment the string, not just whether one exists?"
        ),

        Problem(
            id: "edit-distance",
            title: "Edit Distance",
            difficulty: .hard,
            topics: [.dynamicProgramming],
            companies: [.google, .microsoft, .openai],
            prompt: "Given two strings `word1` and `word2`, return the minimum number of single-character insert/delete/replace operations to convert word1 into word2.",
            constraints: ["0 ≤ word1.length, word2.length ≤ 500"],
            examples: [
                Example(input: "word1 = \"horse\", word2 = \"ros\"", output: "3", explanation: "horse -> rorse -> rose -> ros")
            ],
            hints: [
                "Think about the last characters of both strings: if they match, you don't need an operation there -- reduce to the same problem on the remaining prefixes.",
                "If they don't match, you have exactly three choices: insert, delete, or replace -- each reduces the problem to a smaller subproblem.",
                "Define dp[i][j] = edit distance between word1[0..<i] and word2[0..<j], and build it up from the empty-string base cases."
            ],
            approaches: [
                Approach(name: "2D bottom-up DP", summary: "dp[i][j] built from dp[i-1][j-1], dp[i-1][j], dp[i][j-1] depending on character match.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(m·n) (reducible to O(min(m,n)))",
                         whenToUse: "The standard, expected solution.",
                         steps: ["dp[0][j] = j, dp[i][0] = i (base cases: pure insertions/deletions)",
                                  "If word1[i-1] == word2[j-1]: dp[i][j] = dp[i-1][j-1]",
                                  "Else: dp[i][j] = 1 + min(dp[i-1][j-1], dp[i-1][j], dp[i][j-1])",
                                  "Return dp[m][n]"])
            ],
            starterCode: [
                .swift: "func minDistance(_ word1: String, _ word2: String) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def min_distance(word1: str, word2: str) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "word-ladder",
            title: "Word Ladder",
            difficulty: .hard,
            topics: [.graphs],
            companies: [.amazon, .google, .linkedin],
            prompt: "Given a `beginWord`, an `endWord`, and a dictionary `wordList`, return the length of the shortest transformation sequence from beginWord to endWord, changing exactly one letter at a time, with every intermediate word in wordList. Return 0 if no such sequence exists.",
            constraints: ["1 ≤ beginWord.length ≤ 10", "1 ≤ wordList.count ≤ 5000"],
            examples: [
                Example(input: "beginWord = \"hit\", endWord = \"cog\", wordList = [\"hot\",\"dot\",\"dog\",\"lot\",\"log\",\"cog\"]",
                        output: "5", explanation: "hit -> hot -> dot -> dog -> cog")
            ],
            hints: [
                "Think of every word as a node, with an edge between two words that differ by exactly one letter -- 'shortest transformation sequence' is then just shortest path.",
                "Shortest path in an unweighted graph is exactly what BFS is for.",
                "Rather than comparing every word pair to build edges upfront (slow), generate all one-letter-changed variants of the current word on the fly and check if they're in the word set."
            ],
            approaches: [
                Approach(name: "BFS over one-letter-swap neighbors", summary: "BFS from beginWord, generating neighbors by trying every letter substitution at every position.",
                         timeComplexity: "O(n · L² ) where n = wordList size, L = word length", spaceComplexity: "O(n · L)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["wordSet = set(wordList); if endWord not in wordSet, return 0",
                                  "BFS from beginWord, level = 1", "At each word, try all 26 letters at each position; if the result is in wordSet and unvisited, enqueue it",
                                  "If you dequeue endWord, return the current level", "If BFS exhausts without finding endWord, return 0"])
            ],
            starterCode: [
                .swift: "func ladderLength(_ beginWord: String, _ endWord: String, _ wordList: [String]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def ladder_length(begin_word: str, end_word: str, word_list: list[str]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "Can you return one of the actual shortest transformation sequences, not just its length?"
        ),

        Problem(
            id: "merge-k-sorted-lists",
            title: "Merge k Sorted Lists",
            difficulty: .hard,
            topics: [.heaps, .linkedList],
            companies: [.amazon, .google, .microsoft, .meta],
            prompt: "You're given an array of `k` linked lists, each sorted in ascending order. Merge them all into one sorted linked list.",
            constraints: ["0 ≤ k ≤ 10^4", "0 ≤ total number of nodes ≤ 10^4"],
            examples: [
                Example(input: "lists = [[1,4,5],[1,3,4],[2,6]]", output: "[1,1,2,3,4,4,5,6]", explanation: nil)
            ],
            hints: [
                "Merging two lists at a time, k-1 times, works but repeatedly re-scans already-merged data -- can you avoid that redundant work?",
                "At any moment, the next smallest overall value must be the head of one of the k lists -- a min-heap of 'current head of each list' finds that in O(log k).",
                "Pop the smallest head, append it to the result, then push that list's next node (if any) back onto the heap."
            ],
            approaches: [
                Approach(name: "Merge lists pairwise", summary: "Repeatedly merge two lists at a time until one remains.",
                         timeComplexity: "O(N · k) naive, or O(N log k) with divide-and-conquer pairing", spaceComplexity: "O(1) extra",
                         whenToUse: "Simple; divide-and-conquer pairing (merge in a tournament-bracket order) gets it to O(N log k) too.",
                         steps: ["Merge lists[0] and lists[1], result with lists[2], etc. (or pair them up divide-and-conquer style)"]),
                Approach(name: "Min-heap of list heads", summary: "Keep the current head of each list in a min-heap; always extract the smallest.",
                         timeComplexity: "O(N log k)", spaceComplexity: "O(k)",
                         whenToUse: "The standard, expected optimal solution.",
                         steps: ["heap = min-heap of (value, listIndex) for each non-empty list's head",
                                  "While heap not empty: pop smallest, append to result, push that list's next node if it exists"])
            ],
            starterCode: [
                .swift: "func mergeKLists(_ lists: [ListNode?]) -> ListNode? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def merge_k_lists(lists):\n    # Write your solution here\n    return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "sliding-window-maximum",
            title: "Sliding Window Maximum",
            difficulty: .hard,
            topics: [.heaps, .slidingWindow],
            companies: [.amazon, .google],
            prompt: "Given an array `nums` and a window size `k`, return the maximum value in each sliding window of size k as it moves from left to right.",
            constraints: ["1 ≤ nums.count ≤ 10^5", "1 ≤ k ≤ nums.count"],
            examples: [
                Example(input: "nums = [1,3,-1,-3,5,3,6,7], k = 3", output: "[3,3,5,5,6,7]", explanation: nil)
            ],
            hints: [
                "Recomputing the max of each window from scratch is O(n·k) -- too slow for large inputs.",
                "You only ever care about a value if it could still become the max of some future window -- any value smaller than a more-recent value can be discarded forever.",
                "A deque holding indices in decreasing order of value (front = current window's max) lets you maintain the max in amortized O(1) per element."
            ],
            approaches: [
                Approach(name: "Monotonic deque", summary: "Keep a deque of indices with decreasing values; the front is always the current window's max.",
                         timeComplexity: "O(n)", spaceComplexity: "O(k)",
                         whenToUse: "The standard, optimal approach.",
                         steps: ["deque = [] (stores indices)",
                                  "For each i: pop from the back while nums[back] < nums[i]; push i",
                                  "Pop from the front if it's outside the window (index ≤ i - k)",
                                  "Once i ≥ k-1, record nums[deque.front] as this window's max"])
            ],
            starterCode: [
                .swift: "func maxSlidingWindow(_ nums: [Int], _ k: Int) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def max_sliding_window(nums: list[int], k: int) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "largest-rectangle-in-histogram",
            title: "Largest Rectangle in Histogram",
            difficulty: .hard,
            topics: [.stack],
            companies: [.amazon, .google],
            prompt: "Given an array of bar heights forming a histogram (each bar has width 1), find the area of the largest rectangle that fits entirely within the histogram.",
            constraints: ["1 ≤ heights.count ≤ 10^5"],
            examples: [
                Example(input: "heights = [2,1,5,6,2,3]", output: "10", explanation: "The rectangle formed by bars of height 5 and 6 (indices 2-3) has area 5*2=10.")
            ],
            hints: [
                "For each bar, the largest rectangle *using that bar's height* extends as far left and right as neighboring bars stay ≥ its height -- finding those bounds naively is O(n) per bar, O(n²) total.",
                "A monotonic increasing stack of bar indices lets you find, for each bar, the nearest shorter bar on both sides in O(n) total.",
                "When you pop a bar from the stack because a shorter bar appears, you now know exactly how wide a rectangle at the popped bar's height can be."
            ],
            approaches: [
                Approach(name: "Monotonic increasing stack", summary: "Maintain a stack of indices with increasing heights; resolve rectangle widths when a shorter bar forces a pop.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard, optimal solution -- a classic hard-tier stack problem.",
                         steps: ["stack = [] (indices), push a sentinel 0-height bar at the end to flush the stack",
                                  "For each i: while stack not empty and heights[i] < heights[stack.top]: h = heights[stack.pop()]",
                                  "width = stack.empty ? i : i - stack.top - 1; area = h * width; track max",
                                  "Push i"])
            ],
            starterCode: [
                .swift: "func largestRectangleArea(_ heights: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def largest_rectangle_area(heights: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "alien-dictionary",
            title: "Alien Dictionary",
            difficulty: .hard,
            topics: [.graphs],
            companies: [.amazon, .google, .uber],
            prompt: "You're given a list of words from an alien language, sorted lexicographically according to that language's unknown letter order. Derive a valid ordering of the alphabet, or report that none exists.",
            constraints: ["1 ≤ words.count ≤ 100"],
            examples: [
                Example(input: "words = [\"wrt\",\"wrf\",\"er\",\"ett\",\"rftt\"]", output: "\"wertf\"", explanation: nil)
            ],
            hints: [
                "Compare each pair of adjacent words: the first position where they differ tells you one letter comes before another -- that's a directed edge.",
                "Once you have all these 'comes before' edges, the alien alphabet order is just a topological sort of that graph.",
                "Watch for the invalid case where a later word is a strict prefix of an earlier one -- that can never happen in a valid sort."
            ],
            approaches: [
                Approach(name: "Build graph from adjacent pairs, then topological sort", summary: "Derive ordering edges from the first differing letter between consecutive words, then topologically sort.",
                         timeComplexity: "O(total characters)", spaceComplexity: "O(1) (bounded alphabet)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["For each adjacent word pair, find the first differing character and add an edge (earlier -> later)",
                                  "Detect the invalid-prefix case and return \"\" if found",
                                  "Topologically sort the resulting letter graph (Kahn's algorithm or DFS)",
                                  "If a cycle is detected, return \"\" (no valid ordering)"])
            ],
            starterCode: [
                .swift: "func alienOrder(_ words: [String]) -> String {\n    // Write your solution here\n    return \"\"\n}\n",
                .python: "def alien_order(words: list[str]) -> str:\n    # Write your solution here\n    return \"\"\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "n-queens",
            title: "N-Queens",
            difficulty: .hard,
            topics: [.backtracking],
            companies: [.microsoft, .apple],
            prompt: "Place `n` queens on an `n x n` chessboard so that no two queens attack each other. Return all distinct board configurations.",
            constraints: ["1 ≤ n ≤ 9"],
            examples: [
                Example(input: "n = 4", output: "2 valid configurations", explanation: nil)
            ],
            hints: [
                "Since no two queens can share a row, you can place exactly one queen per row and just decide which column, row by row.",
                "At each row, try each column; a placement is valid if no earlier queen shares that column or either diagonal.",
                "Track used columns and both diagonals (row - col, row + col) as sets for O(1) validity checks instead of re-scanning the board."
            ],
            approaches: [
                Approach(name: "Row-by-row backtracking with column/diagonal sets", summary: "Place one queen per row, tracking used columns and diagonals for fast conflict checks.",
                         timeComplexity: "O(n!) worst case", spaceComplexity: "O(n) recursion depth",
                         whenToUse: "The standard, expected approach.",
                         steps: ["backtrack(row)", "If row == n: record the board",
                                  "For col in 0..<n: if col, (row-col), and (row+col) are all unused: place queen, recurse, then remove it"])
            ],
            starterCode: [
                .swift: "func solveNQueens(_ n: Int) -> [[String]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def solve_n_queens(n: int) -> list[list[str]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: "Can you solve just for the *count* of solutions more efficiently than generating every board?"
        ),

        Problem(
            id: "longest-consecutive-sequence",
            title: "Longest Consecutive Sequence",
            difficulty: .medium,
            topics: [.arrays],
            companies: [.meta, .amazon],
            prompt: "Given an unsorted array of integers, return the length of the longest run of consecutive integers, in O(n) time.",
            constraints: ["0 ≤ nums.count ≤ 10^5"],
            examples: [
                Example(input: "nums = [100,4,200,1,3,2]", output: "4", explanation: "The consecutive run is 1,2,3,4.")
            ],
            hints: [
                "Sorting first gives an easy O(n log n) solution -- the O(n) requirement means you need something else.",
                "Put every number in a set. A number can only be the *start* of a run if (number - 1) is NOT in the set.",
                "For each such run-start, count upward (num+1, num+2, ...) while values exist in the set -- each number only gets counted this way once across the whole algorithm, keeping it O(n) overall."
            ],
            approaches: [
                Approach(name: "Sort first", summary: "Sort, then scan for the longest consecutive run.",
                         timeComplexity: "O(n log n)", spaceComplexity: "O(1) to O(n)",
                         whenToUse: "Simple fallback if O(n) isn't required.",
                         steps: ["Sort nums", "Scan, tracking current run length vs previous value"]),
                Approach(name: "Hash set, only start counting from run-starts", summary: "Only walk forward from numbers whose predecessor isn't in the set.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The optimal, expected solution.",
                         steps: ["numSet = set(nums)", "For each num in numSet: if num-1 not in numSet (it's a run start):",
                                  "count upward while num+length in numSet; track max length"])
            ],
            starterCode: [
                .swift: "func longestConsecutive(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def longest_consecutive(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "min-stack",
            title: "Min Stack",
            difficulty: .medium,
            topics: [.stack],
            companies: [.amazon, .microsoft, .netflix],
            prompt: "Design a stack that supports `push`, `pop`, `top`, and retrieving the minimum element, all in O(1) time.",
            constraints: ["up to 3 × 10^4 total calls"],
            examples: [
                Example(input: "push(-2); push(0); push(-3); getMin()->-3; pop(); top()->0; getMin()->-2", output: "see explanation", explanation: nil)
            ],
            hints: [
                "Recomputing the minimum on every getMin() call would be O(n) -- you need to track it incrementally.",
                "What if, alongside the main stack, you kept a second stack that always tracks 'the minimum so far at this depth'?",
                "Push the new minimum (min(newValue, currentMin)) onto the min-stack every time you push onto the main stack, and pop both together."
            ],
            approaches: [
                Approach(name: "Auxiliary min-stack", summary: "A parallel stack tracks the running minimum at each depth.",
                         timeComplexity: "O(1) per operation", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["push(x): mainStack.push(x); minStack.push(min(x, minStack.top ?? x))",
                                  "pop(): pop both stacks together", "getMin(): return minStack.top"])
            ],
            starterCode: [
                .swift: "final class MinStack {\n    init() {\n        // Write your solution here\n    }\n    func push(_ val: Int) {\n    }\n    func pop() {\n    }\n    func top() -> Int {\n        return 0\n    }\n    func getMin() -> Int {\n        return 0\n    }\n}\n",
                .python: "class MinStack:\n    def __init__(self):\n        pass\n    def push(self, val: int) -> None:\n        pass\n    def pop(self) -> None:\n        pass\n    def top(self) -> int:\n        return 0\n    def get_min(self) -> int:\n        return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "find-median-from-data-stream",
            title: "Find Median from a Data Stream",
            difficulty: .hard,
            topics: [.heaps],
            companies: [.google, .amazon, .twitter],
            prompt: "Design a data structure that supports adding numbers one at a time from a stream, and efficiently finding the median of all numbers added so far.",
            constraints: ["up to 5 × 10^4 total calls"],
            examples: [
                Example(input: "addNum(1); addNum(2); findMedian()->1.5; addNum(3); findMedian()->2", output: "see explanation", explanation: nil)
            ],
            hints: [
                "Keeping the stream sorted and re-finding the middle each time is O(n) per insertion in the worst case -- can you do better?",
                "Split the numbers into two halves: a max-heap holding the smaller half, and a min-heap holding the larger half.",
                "Keep the two heaps balanced in size (differing by at most 1); the median is then either the top of the larger heap, or the average of both tops."
            ],
            approaches: [
                Approach(name: "Two heaps (max-heap + min-heap)", summary: "Max-heap for the lower half, min-heap for the upper half, kept balanced in size.",
                         timeComplexity: "O(log n) per insertion, O(1) per median query", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["addNum(x): push to the appropriate heap based on comparison to lower.top",
                                  "Rebalance: if size difference > 1, move the top of the larger heap to the smaller one",
                                  "findMedian(): if sizes equal, average both tops; else return the larger heap's top"])
            ],
            starterCode: [
                .swift: "final class MedianFinder {\n    init() {\n        // Write your solution here\n    }\n    func addNum(_ num: Int) {\n    }\n    func findMedian() -> Double {\n        return 0.0\n    }\n}\n",
                .python: "class MedianFinder:\n    def __init__(self):\n        pass\n    def add_num(self, num: int) -> None:\n        pass\n    def find_median(self) -> float:\n        return 0.0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "design-twitter-feed",
            title: "Design a Twitter-Style Feed (Data Structure)",
            difficulty: .medium,
            topics: [.heaps, .graphs],
            companies: [.twitter, .meta, .linkedin],
            prompt: """
            Design a simplified social feed: support `postTweet(userId, tweetId)`, `follow(followerId, followeeId)`, \
            `unfollow(followerId, followeeId)`, and `getNewsFeed(userId)` returning the 10 most recent tweet IDs from \
            people the user follows (including the user themself), most recent first.
            """,
            constraints: ["up to 3 × 10^4 total calls"],
            examples: [
                Example(input: "postTweet(1,5); follow(1,2); postTweet(2,6); getNewsFeed(1) -> [6,5]", output: "see explanation", explanation: nil)
            ],
            hints: [
                "Storing a per-user list of tweets (with a timestamp) plus a per-user set of followees covers the data model.",
                "getNewsFeed needs the top 10 *most recent* tweets across potentially many followees' individual timelines -- that's a classic 'merge k sorted lists, take top 10' shape.",
                "A max-heap keyed by timestamp, seeded with the most recent tweet from each followee's timeline, lets you pull the top 10 in O(k log k) instead of sorting everything."
            ],
            approaches: [
                Approach(name: "Per-user timelines + heap merge", summary: "Each user has a timestamped tweet list; merge the top of each followee's list via a heap.",
                         timeComplexity: "O(k log k) per getNewsFeed call, k = followee count", spaceComplexity: "O(tweets + follows)",
                         whenToUse: "The standard approach for this classic 'design' interview question.",
                         steps: ["postTweet: append (timestamp, tweetId) to that user's timeline",
                                  "follow/unfollow: maintain a set of followees per user",
                                  "getNewsFeed: push the most recent tweet from self + each followee onto a max-heap by timestamp",
                                  "Pop up to 10 times, each time pushing that timeline's next-most-recent tweet"])
            ],
            starterCode: [
                .swift: "final class Twitter {\n    init() {\n        // Write your solution here\n    }\n    func postTweet(_ userId: Int, _ tweetId: Int) {\n    }\n    func getNewsFeed(_ userId: Int) -> [Int] {\n        return []\n    }\n    func follow(_ followerId: Int, _ followeeId: Int) {\n    }\n    func unfollow(_ followerId: Int, _ followeeId: Int) {\n    }\n}\n",
                .python: "class Twitter:\n    def __init__(self):\n        pass\n    def post_tweet(self, user_id: int, tweet_id: int) -> None:\n        pass\n    def get_news_feed(self, user_id: int) -> list[int]:\n        return []\n    def follow(self, follower_id: int, followee_id: int) -> None:\n        pass\n    def unfollow(self, follower_id: int, followee_id: int) -> None:\n        pass\n"
            ],
            followUp: "How would this scale if a user follows millions of accounts?"
        ),

        Problem(
            id: "text-justification",
            title: "Text Justification",
            difficulty: .hard,
            topics: [.arrays, .greedy],
            companies: [.google, .microsoft],
            prompt: "Given an array of words and a line width `maxWidth`, format the text so each line has exactly maxWidth characters, fully justified (extra spaces distributed as evenly as possible, left-heavy), except the last line, which is left-justified with single spaces.",
            constraints: ["1 ≤ words.count ≤ 300", "1 ≤ maxWidth ≤ 100"],
            examples: [
                Example(input: "words = [\"This\",\"is\",\"an\",\"example\",\"of\",\"text\",\"justification.\"], maxWidth = 16",
                        output: "[\"This    is    an\", \"example  of text\", \"justification.  \"]", explanation: nil)
            ],
            hints: [
                "First figure out, greedily, how many words fit on each line: keep adding words while the line (with single spaces) still fits within maxWidth.",
                "Once you know which words are on a line, the spacing math is separate: distribute the leftover space as evenly as possible across the gaps, giving extra space to the leftmost gaps first.",
                "The last line, and any line with only one word, is a special case: left-justify with single spaces and pad the end with spaces."
            ],
            approaches: [
                Approach(name: "Greedy line-fill + space distribution", summary: "Greedily pack words per line, then compute and distribute spacing separately.",
                         timeComplexity: "O(total characters)", spaceComplexity: "O(total characters) for the output",
                         whenToUse: "The standard, expected approach -- more about careful implementation than a clever algorithm.",
                         steps: ["Greedily determine which words belong on each line (fit check using single spaces)",
                                  "For a normal line: totalSpaces = maxWidth - totalWordLength; distribute across (wordCount-1) gaps, extra spaces to the leftmost gaps",
                                  "For the last line or a single-word line: join with single spaces, pad the end with spaces to maxWidth"])
            ],
            starterCode: [
                .swift: "func fullJustify(_ words: [String], _ maxWidth: Int) -> [String] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def full_justify(words: list[str], max_width: int) -> list[str]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "task-scheduler",
            title: "Task Scheduler",
            difficulty: .medium,
            topics: [.greedy, .heaps],
            companies: [.amazon, .google, .uber],
            prompt: "Given an array of CPU tasks (represented as characters) and a cooldown `n` (the same task must be separated by at least n intervals), return the minimum number of time units the CPU needs to finish all tasks (idling if necessary).",
            constraints: ["1 ≤ tasks.count ≤ 10^4", "0 ≤ n ≤ 100"],
            examples: [
                Example(input: "tasks = [\"A\",\"A\",\"A\",\"B\",\"B\",\"B\"], n = 2", output: "8", explanation: "A B idle A B idle A B")
            ],
            hints: [
                "The most frequent task is the real bottleneck -- it dictates a minimum number of 'cooldown slots' that need to be filled.",
                "Picture the most frequent task's occurrences as anchors with (n) empty slots between each pair -- other tasks (and idle time) fill those slots.",
                "The answer is the larger of: (a) just running every task back-to-back with no idle, or (b) the frame built around the most frequent task(s)."
            ],
            approaches: [
                Approach(name: "Greedy frame around the max-frequency task", summary: "Compute a lower-bound 'frame' size from the most frequent task's count, compare to just running everything.",
                         timeComplexity: "O(n) after counting", spaceComplexity: "O(1) (fixed alphabet)",
                         whenToUse: "The standard, expected optimal solution.",
                         steps: ["Count task frequencies", "maxFreq = highest count; numMax = how many tasks share that max count",
                                  "frame = (maxFreq - 1) * (n + 1) + numMax",
                                  "Return max(tasks.count, frame)"])
            ],
            starterCode: [
                .swift: "func leastInterval(_ tasks: [Character], _ n: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def least_interval(tasks: list[str], n: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "insert-interval",
            title: "Insert Interval",
            difficulty: .medium,
            topics: [.intervals],
            companies: [.google, .amazon, .uber],
            prompt: "Given a set of non-overlapping intervals sorted by start time, and a new interval, insert it into the list (merging if necessary so the result stays sorted and non-overlapping).",
            constraints: ["0 ≤ intervals.count ≤ 10^4"],
            examples: [
                Example(input: "intervals = [[1,3],[6,9]], newInterval = [2,5]", output: "[[1,5],[6,9]]", explanation: nil)
            ],
            hints: [
                "You don't need to re-sort anything -- the existing intervals are already sorted, so you can walk them once.",
                "Split the walk into three phases: intervals entirely before the new one (copy as-is), intervals overlapping the new one (merge into it), and intervals entirely after (copy as-is)."
            ],
            approaches: [
                Approach(name: "Single linear pass, three phases", summary: "Copy non-overlapping-before intervals, merge all overlapping ones into newInterval, copy non-overlapping-after intervals.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected optimal solution.",
                         steps: ["While interval.end < newInterval.start: copy interval, advance",
                                  "While interval.start ≤ newInterval.end: merge into newInterval (expand its bounds), advance",
                                  "Append the merged newInterval", "Copy all remaining intervals as-is"])
            ],
            starterCode: [
                .swift: "func insert(_ intervals: [[Int]], _ newInterval: [Int]) -> [[Int]] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def insert(intervals: list[list[int]], new_interval: list[int]) -> list[list[int]]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "gas-station",
            title: "Gas Station",
            difficulty: .medium,
            topics: [.greedy],
            companies: [.amazon, .uber],
            prompt: "There are `n` gas stations in a circle. You have `gas[i]` fuel at station i, and it costs `cost[i]` to travel from station i to i+1. Starting with an empty tank at some station, return the starting index that lets you complete the circuit, or -1 if impossible (the answer is guaranteed unique if it exists).",
            constraints: ["1 ≤ n ≤ 10^5"],
            examples: [
                Example(input: "gas = [1,2,3,4,5], cost = [3,4,5,1,2]", output: "3", explanation: nil)
            ],
            hints: [
                "First check feasibility: if total gas < total cost overall, no starting point can ever work.",
                "If a total solution exists, here's the key greedy insight: if you run out of fuel trying to reach station j from some start, then no station between start and j could have worked as a start either -- so you can jump your candidate start straight past the failure point.",
                "Track a running tank total as you sweep once; whenever it goes negative, reset the candidate start to the next station and reset the running total to 0."
            ],
            approaches: [
                Approach(name: "Greedy single pass", summary: "Track a running tank; reset the candidate start whenever the tank goes negative.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard, optimal solution.",
                         steps: ["If sum(gas) < sum(cost): return -1", "tank = 0, start = 0",
                                  "For i in 0..<n: tank += gas[i] - cost[i]",
                                  "If tank < 0: start = i + 1; tank = 0",
                                  "Return start"])
            ],
            starterCode: [
                .swift: "func canCompleteCircuit(_ gas: [Int], _ cost: [Int]) -> Int {\n    // Write your solution here\n    return -1\n}\n",
                .python: "def can_complete_circuit(gas: list[int], cost: list[int]) -> int:\n    # Write your solution here\n    return -1\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "jump-game",
            title: "Jump Game",
            difficulty: .medium,
            topics: [.greedy, .arrays],
            companies: [.amazon, .microsoft],
            prompt: "Given an array `nums` where `nums[i]` is the maximum jump length from index i, return true if you can reach the last index starting from index 0.",
            constraints: ["1 ≤ nums.count ≤ 10^4"],
            examples: [
                Example(input: "nums = [2,3,1,1,4]", output: "true", explanation: nil),
                Example(input: "nums = [3,2,1,0,4]", output: "false", explanation: "You get stuck at index 3.")
            ],
            hints: [
                "You don't need to try every possible jump sequence -- just track the farthest index you could possibly reach so far.",
                "Sweep left to right; if the current index is ever beyond the farthest-reachable-so-far, you're stuck and can stop early.",
                "Update farthest = max(farthest, i + nums[i]) at each index; if farthest ever reaches or passes the last index, you're done."
            ],
            approaches: [
                Approach(name: "Greedy farthest-reach tracking", summary: "Track the farthest reachable index while sweeping once; bail early if you fall behind it.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard, optimal solution.",
                         steps: ["farthest = 0", "For i in 0..<n: if i > farthest, return false",
                                  "farthest = max(farthest, i + nums[i])",
                                  "If farthest ≥ n-1, return true"])
            ],
            starterCode: [
                .swift: "func canJump(_ nums: [Int]) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def can_jump(nums: list[int]) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: "Can you find the *minimum* number of jumps needed to reach the end?"
        ),

        Problem(
            id: "decode-ways",
            title: "Decode Ways",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.microsoft, .amazon],
            prompt: "A message of digits can be decoded where 'A'=\"1\" through 'Z'=\"26\". Given a digit string `s`, return the number of ways it can be decoded.",
            constraints: ["1 ≤ s.length ≤ 100"],
            examples: [
                Example(input: "s = \"226\"", output: "3", explanation: "\"BZ\" (2 26), \"VF\" (22 6), \"BBF\" (2 2 6)")
            ],
            hints: [
                "At each position, you're deciding: decode the current digit alone, or pair it with the next digit -- but only if that pairing is valid (10-26, and the single digit can't be '0').",
                "Define dp[i] = number of ways to decode the first i characters. dp[0] = 1 (empty prefix, one way: do nothing).",
                "dp[i] pulls from dp[i-1] (if s[i-1] is a valid single digit, i.e. not '0') and from dp[i-2] (if s[i-2..<i] is a valid two-digit code, 10-26)."
            ],
            approaches: [
                Approach(name: "Bottom-up DP", summary: "dp[i] sums contributions from a valid single-digit decode and a valid two-digit decode ending at i.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n) (reducible to O(1))",
                         whenToUse: "The standard, expected solution.",
                         steps: ["dp[0] = 1", "For i in 1...n: if s[i-1] != '0': dp[i] += dp[i-1]",
                                  "If i ≥ 2 and s[i-2..<i] is between \"10\" and \"26\": dp[i] += dp[i-2]",
                                  "Return dp[n]"])
            ],
            starterCode: [
                .swift: "func numDecodings(_ s: String) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def num_decodings(s: str) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "unique-paths",
            title: "Unique Paths",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.amazon, .google, .uber],
            prompt: "A robot sits at the top-left of an `m x n` grid and can only move right or down. How many unique paths are there to the bottom-right corner?",
            constraints: ["1 ≤ m, n ≤ 100"],
            examples: [
                Example(input: "m = 3, n = 7", output: "28", explanation: nil)
            ],
            hints: [
                "The number of ways to reach any cell is the sum of the ways to reach the cell above it and the cell to its left.",
                "This is a straightforward 2D DP table, but you can compress it to a single 1D row since each row only depends on the row above.",
                "There's also a closed-form combinatorics answer: it's choosing (m-1) down-moves out of (m+n-2) total moves."
            ],
            approaches: [
                Approach(name: "2D DP", summary: "dp[i][j] = dp[i-1][j] + dp[i][j-1], with the top row and left column all 1s.",
                         timeComplexity: "O(m·n)", spaceComplexity: "O(m·n), reducible to O(n)",
                         whenToUse: "The standard, intuitive solution.",
                         steps: ["dp[0][*] = 1, dp[*][0] = 1", "dp[i][j] = dp[i-1][j] + dp[i][j-1]", "Return dp[m-1][n-1]"]),
                Approach(name: "Combinatorics", summary: "The answer is C(m+n-2, m-1).",
                         timeComplexity: "O(min(m,n))", spaceComplexity: "O(1)",
                         whenToUse: "A slick O(1)-space follow-up if you spot the combinatorial structure.",
                         steps: ["Compute C(m+n-2, m-1) directly using an iterative product to avoid overflow"])
            ],
            starterCode: [
                .swift: "func uniquePaths(_ m: Int, _ n: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def unique_paths(m: int, n: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "What if some cells contain obstacles that block the path?"
        ),

        Problem(
            id: "min-window-substring",
            title: "Minimum Window Substring",
            difficulty: .hard,
            topics: [.slidingWindow],
            companies: [.amazon, .meta, .microsoft],
            prompt: "Given strings `s` and `t`, return the smallest substring of s that contains every character of t (including duplicates). Return an empty string if no such substring exists.",
            constraints: ["1 ≤ s.length, t.length ≤ 10^5"],
            examples: [
                Example(input: "s = \"ADOBECODEBANC\", t = \"ABC\"", output: "\"BANC\"", explanation: nil)
            ],
            hints: [
                "Checking every substring of s against t's requirements is far too slow -- a sliding window that grows and shrinks is the right shape.",
                "Expand the window's right edge until it satisfies all of t's character-count requirements, then shrink from the left as much as possible while it still satisfies them, recording the smallest valid window along the way.",
                "Track how many of t's distinct required characters are currently 'fully satisfied' in the window, so you can check window-validity in O(1) instead of rescanning counts."
            ],
            approaches: [
                Approach(name: "Sliding window with character counts", summary: "Expand right until valid, shrink left while still valid, tracking the smallest valid window seen.",
                         timeComplexity: "O(s.length + t.length)", spaceComplexity: "O(alphabet size)",
                         whenToUse: "The standard, expected optimal solution.",
                         steps: ["need = character counts of t; window = {}; have = 0, required = need.distinctCount",
                                  "Expand right: add s[right] to window; if it now matches need[char] exactly, have += 1",
                                  "While have == required: record window if smaller; shrink from left, decrementing have if a needed count drops below requirement"])
            ],
            starterCode: [
                .swift: "func minWindow(_ s: String, _ t: String) -> String {\n    // Write your solution here\n    return \"\"\n}\n",
                .python: "def min_window(s: str, t: str) -> str:\n    # Write your solution here\n    return \"\"\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "two-sum-ii-sorted",
            title: "Two Sum II - Input Array Is Sorted",
            difficulty: .easy,
            topics: [.twoPointers],
            companies: [.google, .amazon],
            prompt: "Given a 1-indexed array of integers already sorted in ascending order, find two numbers that add up to a target and return their indices (1-indexed).",
            constraints: ["2 ≤ numbers.count ≤ 3 × 10^4"],
            examples: [
                Example(input: "numbers = [2,7,11,15], target = 9", output: "[1,2]", explanation: nil)
            ],
            hints: [
                "You could hash-map this like the original Two Sum, but the array being SORTED is a strong hint toward something cheaper.",
                "Two pointers from both ends: if the sum is too big, move the right pointer in; if too small, move the left pointer up."
            ],
            approaches: [
                Approach(name: "Two pointers", summary: "Start at both ends; move inward based on how the current sum compares to target.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The intended, optimal solution given the sorted input.",
                         steps: ["left = 0, right = n-1", "While left < right: sum = numbers[left] + numbers[right]",
                                  "If sum == target, return [left+1, right+1]", "If sum < target, left += 1, else right -= 1"])
            ],
            starterCode: [
                .swift: "func twoSum(_ numbers: [Int], _ target: Int) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def two_sum(numbers: list[int], target: int) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "remove-duplicates-sorted-array",
            title: "Remove Duplicates from Sorted Array",
            difficulty: .easy,
            topics: [.twoPointers, .arrays],
            companies: [.meta, .microsoft],
            prompt: "Given a sorted array `nums`, remove the duplicates in place so each unique element appears only once, and return the new length. Do this with O(1) extra space.",
            constraints: ["1 ≤ nums.count ≤ 3 × 10^4"],
            examples: [
                Example(input: "nums = [1,1,2]", output: "2, nums = [1,2,...]", explanation: nil)
            ],
            hints: [
                "Since the array is sorted, duplicates are always adjacent -- you never need to look further than the last kept value.",
                "Keep a 'write pointer' for the next unique slot; a 'read pointer' scans forward, only writing when it finds a new value."
            ],
            approaches: [
                Approach(name: "Two-pointer in-place overwrite", summary: "Write each new unique value forward as you scan once.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard optimal solution.",
                         steps: ["writeIndex = 1", "For i in 1..<n: if nums[i] != nums[writeIndex-1]: nums[writeIndex] = nums[i]; writeIndex += 1",
                                  "Return writeIndex"])
            ],
            starterCode: [
                .swift: "func removeDuplicates(_ nums: inout [Int]) -> Int {\n    // Write your solution here\n    return nums.count\n}\n",
                .python: "def remove_duplicates(nums: list[int]) -> int:\n    # Write your solution here, modify nums in place\n    return len(nums)\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "first-bad-version",
            title: "First Bad Version",
            difficulty: .easy,
            topics: [.binarySearch],
            companies: [.google, .meta],
            prompt: "You have `n` versions [1, 2, ..., n], and want to find the first bad one given an API `isBadVersion(version)`. Once a version is bad, all following versions are also bad. Minimize API calls.",
            constraints: ["1 ≤ n ≤ 2^31 - 1"],
            examples: [
                Example(input: "n = 5, first bad = 4", output: "4", explanation: nil)
            ],
            hints: [
                "The versions form a sorted boolean sequence (good...good, bad...bad) -- exactly the shape binary search is built for.",
                "At each guess, call isBadVersion(mid); if bad, the answer is at or before mid, otherwise it's after mid."
            ],
            approaches: [
                Approach(name: "Binary search on the boundary", summary: "Standard binary search narrowing toward the first 'bad' version.",
                         timeComplexity: "O(log n)", spaceComplexity: "O(1)",
                         whenToUse: "The intended, optimal solution.",
                         steps: ["left = 1, right = n", "While left < right: mid = left + (right-left)/2",
                                  "If isBadVersion(mid): right = mid, else: left = mid + 1", "Return left"])
            ],
            starterCode: [
                .swift: "func firstBadVersion(_ n: Int) -> Int {\n    // Write your solution here (assume an isBadVersion(_:) API exists)\n    return 1\n}\n",
                .python: "def first_bad_version(n: int) -> int:\n    # Write your solution here (assume an is_bad_version() API exists)\n    return 1\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "sqrt-x",
            title: "Sqrt(x)",
            difficulty: .easy,
            topics: [.binarySearch, .math],
            companies: [.linkedin, .amazon],
            prompt: "Given a non-negative integer `x`, return the integer square root of x truncated toward zero, without using a built-in power/sqrt function.",
            constraints: ["0 ≤ x ≤ 2^31 - 1"],
            examples: [
                Example(input: "x = 8", output: "2", explanation: "sqrt(8) ≈ 2.83, truncated to 2.")
            ],
            hints: [
                "You're searching for the largest integer whose square is ≤ x -- the search space [0, x] is sorted by that property.",
                "Binary search on the candidate answer, checking mid*mid against x (watch for overflow with large x in other languages)."
            ],
            approaches: [
                Approach(name: "Binary search on the answer", summary: "Search the range [0, x] for the largest value whose square doesn't exceed x.",
                         timeComplexity: "O(log x)", spaceComplexity: "O(1)",
                         whenToUse: "The standard optimal approach without library functions.",
                         steps: ["left = 0, right = x", "While left ≤ right: mid = (left+right)/2",
                                  "If mid*mid ≤ x: best = mid; left = mid + 1", "Else: right = mid - 1", "Return best"])
            ],
            starterCode: [
                .swift: "func mySqrt(_ x: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def my_sqrt(x: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "implement-queue-using-stacks",
            title: "Implement Queue using Stacks",
            difficulty: .easy,
            topics: [.stack],
            companies: [.amazon, .microsoft],
            prompt: "Implement a first-in-first-out (FIFO) queue using only two stacks, supporting push, pop, peek, and empty.",
            constraints: ["up to 100 total calls"],
            examples: [
                Example(input: "push(1); push(2); peek() -> 1; pop() -> 1; empty() -> false", output: "see explanation", explanation: nil)
            ],
            hints: [
                "A single stack reverses order (LIFO); to get FIFO order back, you need to reverse it a second time.",
                "Use an 'in' stack for pushes. When you need to pop/peek and the 'out' stack is empty, dump everything from 'in' into 'out' -- that reverses it back to FIFO order."
            ],
            approaches: [
                Approach(name: "Two stacks, lazy transfer", summary: "Push onto 'in'; transfer to 'out' only when 'out' is empty and you need to read the front.",
                         timeComplexity: "O(1) amortized per operation", spaceComplexity: "O(n)",
                         whenToUse: "The standard, optimal approach.",
                         steps: ["push(x): inStack.push(x)",
                                  "pop()/peek(): if outStack is empty, move everything from inStack to outStack",
                                  "Then pop/peek from outStack"])
            ],
            starterCode: [
                .swift: "final class MyQueue {\n    init() {\n        // Write your solution here\n    }\n    func push(_ x: Int) {\n    }\n    func pop() -> Int {\n        return 0\n    }\n    func peek() -> Int {\n        return 0\n    }\n    func empty() -> Bool {\n        return true\n    }\n}\n",
                .python: "class MyQueue:\n    def __init__(self):\n        pass\n    def push(self, x: int) -> None:\n        pass\n    def pop(self) -> int:\n        return 0\n    def peek(self) -> int:\n        return 0\n    def empty(self) -> bool:\n        return True\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "house-robber",
            title: "House Robber",
            difficulty: .easy,
            topics: [.dynamicProgramming],
            companies: [.amazon, .microsoft],
            prompt: "Given an array representing money in houses along a street, find the maximum amount you can rob without robbing two directly adjacent houses.",
            constraints: ["1 ≤ nums.count ≤ 100"],
            examples: [
                Example(input: "nums = [1,2,3,1]", output: "4", explanation: "Rob house 1 (1) and house 3 (3) -> 4. Or house 2 and 4 -> 3. Best is 4 by robbing houses 1 and 3? Actually best is houses 2 and 4: 2+1=3, or 1+3=4 (indices 0 and 2).")
            ],
            hints: [
                "At each house, you have two choices: skip it (carry forward the best so far) or rob it (best-so-far from two houses back, plus this house's money).",
                "Track just two running values -- the best total ending at the previous house, and the one before that -- rather than a full array."
            ],
            approaches: [
                Approach(name: "DP with two rolling variables", summary: "At each house, take the max of skipping it or robbing it plus the best from two houses back.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard, optimal solution.",
                         steps: ["prev2 = 0, prev1 = 0", "For each money in nums: current = max(prev1, prev2 + money)",
                                  "prev2 = prev1; prev1 = current", "Return prev1"])
            ],
            starterCode: [
                .swift: "func rob(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def rob(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "What if the houses are arranged in a circle (first and last are adjacent)?"
        ),

        Problem(
            id: "kth-smallest-in-bst",
            title: "Kth Smallest Element in a BST",
            difficulty: .medium,
            topics: [.trees, .binarySearch],
            companies: [.google, .amazon],
            prompt: "Given the root of a binary search tree and an integer k, return the kth smallest value in the tree (1-indexed).",
            constraints: ["1 ≤ number of nodes ≤ 10^4"],
            examples: [
                Example(input: "root = [3,1,4,null,2], k = 1", output: "1", explanation: nil)
            ],
            hints: [
                "A BST's in-order traversal visits nodes in sorted order -- that's exactly the ordering you need.",
                "You don't need to collect the entire sorted list; stop as soon as you've visited the kth node."
            ],
            approaches: [
                Approach(name: "In-order traversal with an early stop", summary: "Traverse in-order (left, node, right), counting nodes visited; stop at the kth.",
                         timeComplexity: "O(h + k)", spaceComplexity: "O(h) recursion stack",
                         whenToUse: "The standard, optimal approach -- can be done iteratively with an explicit stack to avoid full recursion.",
                         steps: ["Iterative in-order traversal using a stack", "Each time you pop/visit a node, decrement a counter",
                                  "When the counter hits 0, that node's value is the answer"])
            ],
            starterCode: [
                .swift: "func kthSmallest(_ root: TreeNode?, _ k: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def kth_smallest(root, k: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "What if the BST is modified (insert/delete) frequently and you need kth-smallest repeatedly -- how would you optimize?"
        ),

        Problem(
            id: "lowest-common-ancestor-bst",
            title: "Lowest Common Ancestor of a BST",
            difficulty: .medium,
            topics: [.trees, .binarySearch],
            companies: [.amazon, .microsoft, .linkedin],
            prompt: "Given a binary search tree and two nodes p and q, find their lowest common ancestor (the deepest node that has both as descendants).",
            constraints: ["2 ≤ number of nodes ≤ 10^5"],
            examples: [
                Example(input: "root = [6,2,8,0,4,7,9,null,null,3,5], p = 2, q = 8", output: "6", explanation: nil)
            ],
            hints: [
                "This is a BST, not just any binary tree -- the values themselves tell you which direction to go, no need to search both subtrees.",
                "If both p and q are less than the current node, the LCA must be in the left subtree; if both are greater, it's in the right subtree; otherwise, the current node IS the LCA (it's the split point)."
            ],
            approaches: [
                Approach(name: "BST property walk", summary: "Walk down from the root, following BST ordering, until you reach the split point.",
                         timeComplexity: "O(h)", spaceComplexity: "O(1) iterative",
                         whenToUse: "The optimal approach, exploiting BST structure -- much faster than a general tree LCA.",
                         steps: ["node = root", "While true: if p.val and q.val both < node.val: node = node.left",
                                  "Else if both > node.val: node = node.right", "Else: return node"])
            ],
            starterCode: [
                .swift: "func lowestCommonAncestor(_ root: TreeNode?, _ p: TreeNode?, _ q: TreeNode?) -> TreeNode? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def lowest_common_ancestor(root, p, q):\n    # Write your solution here\n    return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "lowest-common-ancestor-binary-tree",
            title: "Lowest Common Ancestor of a Binary Tree",
            difficulty: .medium,
            topics: [.trees],
            companies: [.meta, .amazon],
            prompt: "Given a (not-necessarily-sorted) binary tree and two nodes p and q, find their lowest common ancestor.",
            constraints: ["2 ≤ number of nodes ≤ 10^5"],
            examples: [
                Example(input: "root = [3,5,1,6,2,0,8,null,null,7,4], p = 5, q = 1", output: "3", explanation: nil)
            ],
            hints: [
                "Without BST ordering to guide you, you generally need to search both subtrees at every node.",
                "Recursively ask each subtree 'is p or q found here?'. If both left and right report finding one, the current node is the LCA; otherwise propagate whichever side found something."
            ],
            approaches: [
                Approach(name: "Recursive search both subtrees", summary: "At each node, recurse into both children; if both return non-nil, this node is the LCA.",
                         timeComplexity: "O(n)", spaceComplexity: "O(h) recursion stack",
                         whenToUse: "The standard, optimal solution for a general binary tree.",
                         steps: ["If node is nil or node == p or node == q: return node",
                                  "left = search(node.left, p, q); right = search(node.right, p, q)",
                                  "If both left and right are non-nil: return node (this is the LCA)",
                                  "Otherwise return whichever of left/right is non-nil"])
            ],
            starterCode: [
                .swift: "func lowestCommonAncestor(_ root: TreeNode?, _ p: TreeNode?, _ q: TreeNode?) -> TreeNode? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def lowest_common_ancestor(root, p, q):\n    # Write your solution here\n    return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "binary-tree-right-side-view",
            title: "Binary Tree Right Side View",
            difficulty: .medium,
            topics: [.trees, .graphs],
            companies: [.amazon, .meta],
            prompt: "Given the root of a binary tree, return the values visible when looking at the tree from the right side, top to bottom (one value per level).",
            constraints: ["0 ≤ number of nodes ≤ 100"],
            examples: [
                Example(input: "root = [1,2,3,null,5,null,4]", output: "[1,3,4]", explanation: nil)
            ],
            hints: [
                "'What you see from the right' at each level is just the LAST node visited at that level during a level-order (BFS) traversal.",
                "BFS level by level, and take the last node's value from each level's queue snapshot."
            ],
            approaches: [
                Approach(name: "Level-order BFS, keep the last per level", summary: "BFS level by level; record the last node's value in each level.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard, intuitive solution.",
                         steps: ["queue = [root]", "While queue not empty: levelSize = queue.count",
                                  "For i in 0..<levelSize: pop front; if i == levelSize-1, record its value; enqueue its children"])
            ],
            starterCode: [
                .swift: "func rightSideView(_ root: TreeNode?) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def right_side_view(root) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "add-two-numbers",
            title: "Add Two Numbers",
            difficulty: .medium,
            topics: [.linkedList, .math],
            companies: [.amazon, .microsoft, .apple],
            prompt: "You're given two non-empty linked lists representing two non-negative integers, digits stored in reverse order, one digit per node. Add the two numbers and return the sum as a linked list in the same format.",
            constraints: ["1 ≤ number of nodes in each list ≤ 100"],
            examples: [
                Example(input: "l1 = 2->4->3, l2 = 5->6->4", output: "7->0->8", explanation: "342 + 465 = 807")
            ],
            hints: [
                "This is just elementary-school column addition, one linked-list node at a time instead of one digit at a time.",
                "Track a running carry; at each position, sum = digit1 + digit2 + carry, the new node's value is sum % 10, and the new carry is sum / 10.",
                "Don't forget a final carry-out node if the numbers' lengths differ or the last addition still carries."
            ],
            approaches: [
                Approach(name: "Simulated column addition", summary: "Walk both lists together, tracking a carry, building the result list as you go.",
                         timeComplexity: "O(max(m, n))", spaceComplexity: "O(max(m, n)) for the output",
                         whenToUse: "The standard, expected solution.",
                         steps: ["dummy = ListNode(); tail = dummy; carry = 0",
                                  "While l1 or l2 or carry: sum = (l1?.val ?? 0) + (l2?.val ?? 0) + carry",
                                  "carry = sum / 10; tail.next = ListNode(sum % 10); tail = tail.next; advance l1/l2 if present",
                                  "Return dummy.next"])
            ],
            starterCode: [
                .swift: "func addTwoNumbers(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def add_two_numbers(l1, l2):\n    # Write your solution here\n    return None\n"
            ],
            followUp: "What if the digits were stored in forward (non-reversed) order instead?"
        ),

        Problem(
            id: "remove-nth-node-from-end",
            title: "Remove Nth Node From End of List",
            difficulty: .medium,
            topics: [.linkedList, .twoPointers],
            companies: [.amazon, .google],
            prompt: "Given the head of a linked list, remove the nth node from the end and return the head, in one pass.",
            constraints: ["1 ≤ number of nodes ≤ 30"],
            examples: [
                Example(input: "head = [1,2,3,4,5], n = 2", output: "[1,2,3,5]", explanation: nil)
            ],
            hints: [
                "Without knowing the list's length ahead of time, 'nth from the end' is awkward -- unless two pointers stay a fixed n apart.",
                "Advance a 'fast' pointer n steps ahead first, then move both fast and 'slow' together; when fast reaches the end, slow is right before the node to remove.",
                "A dummy head node before the real head avoids a special case when the node to remove is the head itself."
            ],
            approaches: [
                Approach(name: "Two pointers, n apart", summary: "Advance fast n steps ahead, then move both together until fast falls off the end.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard one-pass optimal solution.",
                         steps: ["dummy = ListNode(next: head); slow = dummy; fast = dummy",
                                  "Advance fast n+1 times", "While fast is non-nil: advance both slow and fast",
                                  "slow.next = slow.next.next", "Return dummy.next"])
            ],
            starterCode: [
                .swift: "func removeNthFromEnd(_ head: ListNode?, _ n: Int) -> ListNode? {\n    // Write your solution here\n    return head\n}\n",
                .python: "def remove_nth_from_end(head, n: int):\n    # Write your solution here\n    return head\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "copy-list-with-random-pointer",
            title: "Copy List with Random Pointer",
            difficulty: .medium,
            topics: [.linkedList],
            companies: [.amazon, .meta, .microsoft],
            prompt: "You're given a linked list where each node has a `next` pointer and a `random` pointer that can point to any node in the list (or nil). Return a complete deep copy of the list.",
            constraints: ["0 ≤ number of nodes ≤ 1000"],
            examples: [
                Example(input: "list with next + random pointers", output: "a structurally identical, fully independent deep copy", explanation: nil)
            ],
            hints: [
                "The tricky part is the random pointers -- when you clone a node, the node its random pointer targets might not be cloned yet.",
                "A hash map from original node -> cloned node lets you look up (or lazily create) the correct clone for any random target, in two passes.",
                "There's also a clever O(1)-space trick: interleave each clone directly after its original in the list, use that to wire up random pointers, then unweave the two lists."
            ],
            approaches: [
                Approach(name: "Hash map original -> clone", summary: "First pass clones nodes and builds a lookup map; second pass wires up next/random using the map.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The simplest, most commonly given optimal-time solution.",
                         steps: ["First pass: create a clone for each node, map[original] = clone",
                                  "Second pass: clone.next = map[original.next], clone.random = map[original.random]",
                                  "Return map[head]"]),
                Approach(name: "Interleaved nodes, O(1) extra space", summary: "Weave each clone right after its original, use that adjacency to set random pointers, then unweave.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1) extra (excluding output)",
                         whenToUse: "A strong follow-up if asked to avoid the hash map.",
                         steps: ["Insert clone_i right after original_i for every node",
                                  "For each original: original.next.random = original.random?.next",
                                  "Unweave: separate the interleaved list back into original and cloned lists"])
            ],
            starterCode: [
                .swift: "// class Node { var val: Int; var next: Node?; var random: Node?; init(_ v: Int) { val = v } }\nfunc copyRandomList(_ head: Node?) -> Node? {\n    // Write your solution here\n    return nil\n}\n",
                .python: "def copy_random_list(head):\n    # Write your solution here\n    return None\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "find-all-anagrams-in-string",
            title: "Find All Anagrams in a String",
            difficulty: .medium,
            topics: [.slidingWindow],
            companies: [.amazon, .meta],
            prompt: "Given strings `s` and `p`, return the starting indices of all anagrams of `p` within `s`.",
            constraints: ["1 ≤ s.length, p.length ≤ 3 × 10^4"],
            examples: [
                Example(input: "s = \"cbaebabacd\", p = \"abc\"", output: "[0,6]", explanation: nil)
            ],
            hints: [
                "Every anagram of p has the exact same character-count signature as p -- you're really looking for windows of s matching that signature.",
                "A fixed-size sliding window of length p.length lets you maintain a running character count and compare it to p's count as the window slides, in O(1) per step rather than recomputing from scratch."
            ],
            approaches: [
                Approach(name: "Fixed-size sliding window with character counts", summary: "Slide a window of length p.length across s, incrementally updating counts and comparing to p's signature.",
                         timeComplexity: "O(s.length)", spaceComplexity: "O(1) (fixed alphabet)",
                         whenToUse: "The standard, optimal approach.",
                         steps: ["need = character counts of p", "window = character counts of s[0..<p.length]",
                                  "If window == need: record index 0",
                                  "Slide right by one: add new char, remove leftmost char, compare counts again"])
            ],
            starterCode: [
                .swift: "func findAnagrams(_ s: String, _ p: String) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def find_anagrams(s: str, p: str) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "longest-repeating-char-replacement",
            title: "Longest Repeating Character Replacement",
            difficulty: .medium,
            topics: [.slidingWindow],
            companies: [.google, .amazon],
            prompt: "Given a string `s` and an integer `k`, you can replace up to k characters in the string. Return the length of the longest substring containing the same letter after such replacements.",
            constraints: ["1 ≤ s.length ≤ 10^5", "0 ≤ k ≤ s.length"],
            examples: [
                Example(input: "s = \"ABAB\", k = 2", output: "4", explanation: "Replace both 'A's or both 'B's.")
            ],
            hints: [
                "A window is 'achievable' if (window length - count of its most frequent character) ≤ k -- that's exactly how many characters you'd need to replace.",
                "Expand the window each step; if it becomes invalid, shrink from the left. Track the maximum valid window size seen."
            ],
            approaches: [
                Approach(name: "Sliding window with a max-frequency tracker", summary: "Grow the window; shrink from the left whenever (window - maxFreqCount) exceeds k.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1) (fixed alphabet)",
                         whenToUse: "The standard, optimal solution.",
                         steps: ["left = 0, maxFreq = 0, counts = {}", "For right in 0..<n: counts[s[right]] += 1",
                                  "maxFreq = max(maxFreq, counts[s[right]])",
                                  "While (right - left + 1 - maxFreq) > k: counts[s[left]] -= 1; left += 1",
                                  "Track max(right - left + 1)"])
            ],
            starterCode: [
                .swift: "func characterReplacement(_ s: String, _ k: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def character_replacement(s: str, k: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "redundant-connection",
            title: "Redundant Connection",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.google, .uber],
            prompt: "You're given a graph that started as a tree of n nodes, with one extra edge added (creating exactly one cycle). Find the extra edge -- if multiple could be removed to fix the tree, return the one that appears last in the input.",
            constraints: ["3 ≤ n ≤ 1000"],
            examples: [
                Example(input: "edges = [[1,2],[1,3],[2,3]]", output: "[2,3]", explanation: nil)
            ],
            hints: [
                "The 'extra' edge is the one that connects two nodes ALREADY reachable from each other -- adding it is what creates the cycle.",
                "Union-Find (disjoint set union) lets you process edges one at a time and cheaply check 'are these two nodes already in the same component?'",
                "The first edge where both endpoints are already unioned together is your answer."
            ],
            approaches: [
                Approach(name: "Union-Find, first edge that would form a cycle", summary: "Process edges in order, union-ing endpoints; the first edge whose endpoints are already connected is redundant.",
                         timeComplexity: "O(n · α(n))", spaceComplexity: "O(n)",
                         whenToUse: "The standard, optimal approach -- a classic union-find application.",
                         steps: ["parent[i] = i for all nodes", "For each edge (u, v): if find(u) == find(v): return this edge",
                                  "Else: union(u, v)"])
            ],
            starterCode: [
                .swift: "func findRedundantConnection(_ edges: [[Int]]) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def find_redundant_connection(edges: list[list[int]]) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "network-delay-time",
            title: "Network Delay Time",
            difficulty: .medium,
            topics: [.graphs, .heaps],
            companies: [.uber, .google],
            prompt: "You're given a network of `n` nodes and travel times as directed edges (u, v, w). Starting from node `k`, return the minimum time for a signal to reach all nodes, or -1 if impossible.",
            constraints: ["1 ≤ n ≤ 100", "1 ≤ k ≤ n"],
            examples: [
                Example(input: "times = [[2,1,1],[2,3,1],[3,4,1]], n = 4, k = 2", output: "2", explanation: nil)
            ],
            hints: [
                "This is shortest-path-from-a-single-source with weighted edges -- exactly what Dijkstra's algorithm solves.",
                "Use a min-heap of (distance, node), always expanding the closest unvisited node next, and answer with the maximum distance across all reachable nodes (the last one to receive the signal)."
            ],
            approaches: [
                Approach(name: "Dijkstra's algorithm", summary: "Min-heap-driven shortest path from k to every other node; answer is the max distance (or -1 if any node is unreachable).",
                         timeComplexity: "O(E log V)", spaceComplexity: "O(V + E)",
                         whenToUse: "The standard, optimal approach for non-negative weighted shortest paths.",
                         steps: ["Build adjacency list; dist = {k: 0}; heap = [(0, k)]",
                                  "While heap not empty: pop (d, node); skip if already finalized with a better distance",
                                  "For each neighbor: relax distance, push (newDist, neighbor) if improved",
                                  "If all n nodes got a distance, return max(dist.values), else -1"])
            ],
            starterCode: [
                .swift: "func networkDelayTime(_ times: [[Int]], _ n: Int, _ k: Int) -> Int {\n    // Write your solution here\n    return -1\n}\n",
                .python: "def network_delay_time(times: list[list[int]], n: int, k: int) -> int:\n    # Write your solution here\n    return -1\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "course-schedule-ii",
            title: "Course Schedule II",
            difficulty: .medium,
            topics: [.graphs],
            companies: [.google, .amazon],
            prompt: "Given `numCourses` and a list of prerequisite pairs, return a valid order to take all courses, or an empty array if it's impossible (a cycle exists).",
            constraints: ["1 ≤ numCourses ≤ 2000"],
            examples: [
                Example(input: "numCourses = 4, prerequisites = [[1,0],[2,0],[3,1],[3,2]]", output: "[0,1,2,3] (one valid order)", explanation: nil)
            ],
            hints: [
                "This is the same graph as Course Schedule I, but instead of just detecting a cycle, you need to actually produce a valid ordering -- that's a topological sort.",
                "Kahn's algorithm: repeatedly take a course with zero remaining prerequisites, 'take' it, and decrement the prerequisite count of courses that depended on it."
            ],
            approaches: [
                Approach(name: "Kahn's algorithm (BFS topological sort)", summary: "Repeatedly remove zero-in-degree nodes, appending them to the order and decrementing their neighbors' in-degree.",
                         timeComplexity: "O(V + E)", spaceComplexity: "O(V + E)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["Build adjacency list + in-degree count per course",
                                  "queue = all courses with in-degree 0",
                                  "While queue not empty: pop course, append to order; decrement in-degree of its dependents, enqueue any that hit 0",
                                  "If order.count == numCourses, return order; else return [] (cycle detected)"])
            ],
            starterCode: [
                .swift: "func findOrder(_ numCourses: Int, _ prerequisites: [[Int]]) -> [Int] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def find_order(num_courses: int, prerequisites: list[list[int]]) -> list[int]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "house-robber-ii",
            title: "House Robber II",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.amazon],
            prompt: "Same as House Robber, but the houses are arranged in a circle -- the first and last houses are adjacent. Find the maximum amount you can rob.",
            constraints: ["1 ≤ nums.count ≤ 100"],
            examples: [
                Example(input: "nums = [2,3,2]", output: "3", explanation: "Robbing houses 1 and 3 isn't allowed since they're adjacent in the circle; best is just house 2.")
            ],
            hints: [
                "The circular constraint means you can never rob BOTH the first and last house together.",
                "So: either the first house is excluded, or the last house is excluded -- run the original (linear) House Robber on both cases and take the better result."
            ],
            approaches: [
                Approach(name: "Two linear House Robber passes", summary: "Run the linear DP once excluding the first house, once excluding the last, and take the max.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard reduction to the non-circular version.",
                         steps: ["If only one house, return its value",
                                  "result1 = linearRob(nums[0..<n-1]) -- excludes last house",
                                  "result2 = linearRob(nums[1..<n]) -- excludes first house",
                                  "Return max(result1, result2)"])
            ],
            starterCode: [
                .swift: "func rob(_ nums: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def rob(nums: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "partition-equal-subset-sum",
            title: "Partition Equal Subset Sum",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.amazon, .google],
            prompt: "Given an array of positive integers, determine if it can be partitioned into two subsets with equal sum.",
            constraints: ["1 ≤ nums.count ≤ 200"],
            examples: [
                Example(input: "nums = [1,5,11,5]", output: "true", explanation: "[1,5,5] and [11] both sum to 11.")
            ],
            hints: [
                "If the total sum is odd, it's immediately impossible to split evenly -- an easy early exit.",
                "Otherwise this reduces to: 'can some subset of nums sum to exactly totalSum / 2?' -- a classic 0/1 knapsack-shaped question.",
                "dp[s] = true if some subset sums to exactly s; process each number once, updating reachable sums from high to low to avoid reusing a number twice."
            ],
            approaches: [
                Approach(name: "0/1 knapsack subset-sum DP", summary: "Track which sums up to totalSum/2 are reachable using a boolean DP array, one number at a time.",
                         timeComplexity: "O(n · sum)", spaceComplexity: "O(sum)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["If totalSum is odd, return false; target = totalSum / 2",
                                  "dp = array of target+1 falses; dp[0] = true",
                                  "For each num: for s from target down to num: dp[s] = dp[s] || dp[s - num]",
                                  "Return dp[target]"])
            ],
            starterCode: [
                .swift: "func canPartition(_ nums: [Int]) -> Bool {\n    // Write your solution here\n    return false\n}\n",
                .python: "def can_partition(nums: list[int]) -> bool:\n    # Write your solution here\n    return False\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "longest-palindromic-substring",
            title: "Longest Palindromic Substring",
            difficulty: .medium,
            topics: [.dynamicProgramming, .twoPointers],
            companies: [.amazon, .microsoft, .meta],
            prompt: "Given a string `s`, return the longest palindromic substring within it.",
            constraints: ["1 ≤ s.length ≤ 1000"],
            examples: [
                Example(input: "s = \"babad\"", output: "\"bab\" (or \"aba\")", explanation: nil)
            ],
            hints: [
                "Checking every substring for being a palindrome is O(n³) total -- too slow. Think about growing palindromes OUTWARD from a center instead.",
                "Every palindrome has a center -- either a single character (odd length) or a gap between two characters (even length). Try expanding from each of the 2n-1 possible centers.",
                "There's also a DP formulation: a substring is a palindrome if its ends match AND the substring inside those ends is also a palindrome (or is trivially short)."
            ],
            approaches: [
                Approach(name: "Expand around center", summary: "For each of the 2n-1 possible centers, expand outward while characters match, tracking the longest found.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(1)",
                         whenToUse: "The standard approach -- simple and efficient enough for typical constraints.",
                         steps: ["For each center (both single-character and between-character):",
                                  "Expand left/right while s[left] == s[right]",
                                  "Track the longest palindrome found across all centers"]),
                Approach(name: "2D DP table", summary: "dp[i][j] = true if s[i...j] is a palindrome, built from shorter substrings outward.",
                         timeComplexity: "O(n²)", spaceComplexity: "O(n²)",
                         whenToUse: "A more systematic alternative, useful if you also need to answer many palindrome-range queries.",
                         steps: ["dp[i][i] = true for all i", "dp[i][i+1] = (s[i] == s[i+1])",
                                  "For length ≥ 3: dp[i][j] = (s[i]==s[j]) && dp[i+1][j-1]",
                                  "Track the (i,j) pair with the longest true span"])
            ],
            starterCode: [
                .swift: "func longestPalindrome(_ s: String) -> String {\n    // Write your solution here\n    return \"\"\n}\n",
                .python: "def longest_palindrome(s: str) -> str:\n    # Write your solution here\n    return \"\"\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "subarray-sum-equals-k",
            title: "Subarray Sum Equals K",
            difficulty: .medium,
            topics: [.arrays],
            companies: [.meta, .amazon, .google],
            prompt: "Given an integer array `nums` and an integer `k`, return the total number of contiguous subarrays whose sum equals k.",
            constraints: ["1 ≤ nums.count ≤ 2 × 10^4"],
            examples: [
                Example(input: "nums = [1,1,1], k = 2", output: "2", explanation: nil)
            ],
            hints: [
                "The array can contain negative numbers, so a sliding window (which relies on sums only growing as you extend right) doesn't directly work here.",
                "Think in terms of PREFIX sums: subarray (i, j] sums to k exactly when prefixSum[j] - prefixSum[i] == k.",
                "As you scan and track a running prefix sum, ask: 'how many earlier prefix sums equal (currentPrefixSum - k)?' -- a hash map of prefix-sum counts answers that in O(1)."
            ],
            approaches: [
                Approach(name: "Prefix sum + hash map of counts", summary: "Track a running prefix sum and a map of how many times each prefix sum has occurred so far.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n)",
                         whenToUse: "The standard, optimal approach -- handles negative numbers correctly, unlike sliding window.",
                         steps: ["prefixCounts = {0: 1}; sum = 0; result = 0",
                                  "For each num: sum += num", "result += prefixCounts[sum - k] ?? 0",
                                  "prefixCounts[sum] = (prefixCounts[sum] ?? 0) + 1", "Return result"])
            ],
            starterCode: [
                .swift: "func subarraySum(_ nums: [Int], _ k: Int) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def subarray_sum(nums: list[int], k: int) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "best-time-buy-sell-stock-cooldown",
            title: "Best Time to Buy and Sell Stock with Cooldown",
            difficulty: .medium,
            topics: [.dynamicProgramming],
            companies: [.amazon, .google],
            prompt: "Given daily stock prices, maximize profit from as many transactions as you like, but after selling you must wait one day (cooldown) before buying again. You can't hold more than one share at a time.",
            constraints: ["1 ≤ prices.count ≤ 5000"],
            examples: [
                Example(input: "prices = [1,2,3,0,2]", output: "3", explanation: "buy(1) sell(2) cooldown buy(0) sell(2): 1+2=3")
            ],
            hints: [
                "At any given day, you're in one of three states: holding a stock, just sold (in cooldown), or free to buy (not holding, not in cooldown).",
                "Define three running values for 'best profit if I end today in each state', and write a transition for how each state could have been reached from yesterday's states."
            ],
            approaches: [
                Approach(name: "State-machine DP (hold / sold / rest)", summary: "Track the best achievable profit for three daily states, transitioning between them day by day.",
                         timeComplexity: "O(n)", spaceComplexity: "O(1)",
                         whenToUse: "The standard, optimal approach for cooldown-constrained trading problems.",
                         steps: ["hold = -prices[0], sold = 0, rest = 0 (initial day)",
                                  "Each subsequent day: newHold = max(hold, rest - price)",
                                  "newSold = hold + price", "newRest = max(rest, sold)",
                                  "hold, sold, rest = newHold, newSold, newRest",
                                  "Return max(sold, rest) at the end"])
            ],
            starterCode: [
                .swift: "func maxProfit(_ prices: [Int]) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def max_profit(prices: list[int]) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "insert-delete-getrandom",
            title: "Insert Delete GetRandom O(1)",
            difficulty: .medium,
            topics: [.arrays, .heaps],
            companies: [.amazon, .meta],
            prompt: "Design a data structure supporting insert(val), remove(val), and getRandom() (uniformly random existing element), all in average O(1) time.",
            constraints: ["up to 2 × 10^5 total calls"],
            examples: [
                Example(input: "insert(1); insert(2); remove(1); getRandom() -> 2", output: "see explanation", explanation: nil)
            ],
            hints: [
                "A hash set alone gives O(1) insert/remove/contains, but has no way to pick a uniformly random element in O(1) -- you can't index into a set.",
                "An array DOES support O(1) random access by index -- but removing from the middle of an array is O(n) unless you're clever about it.",
                "Combine both: an array for random access, plus a hash map from value -> its index in the array. To remove in O(1), swap the target with the LAST array element before popping, and update the map."
            ],
            approaches: [
                Approach(name: "Array + value-to-index hash map", summary: "Array gives O(1) random access; swap-with-last-then-pop gives O(1) removal; hash map tracks each value's current index.",
                         timeComplexity: "O(1) average per operation", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected solution for this classic design problem.",
                         steps: ["insert(val): if already present, return false; else append to array, map[val] = array.count-1",
                                  "remove(val): if absent, return false; swap array[map[val]] with the last element, update the swapped value's index in map, pop the array, remove val from map",
                                  "getRandom(): return array[random index]"])
            ],
            starterCode: [
                .swift: "final class RandomizedSet {\n    init() {\n        // Write your solution here\n    }\n    func insert(_ val: Int) -> Bool {\n        return false\n    }\n    func remove(_ val: Int) -> Bool {\n        return false\n    }\n    func getRandom() -> Int {\n        return 0\n    }\n}\n",
                .python: "class RandomizedSet:\n    def __init__(self):\n        pass\n    def insert(self, val: int) -> bool:\n        return False\n    def remove(self, val: int) -> bool:\n        return False\n    def get_random(self) -> int:\n        return 0\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "time-based-key-value-store",
            title: "Time Based Key-Value Store",
            difficulty: .medium,
            topics: [.binarySearch, .arrays],
            companies: [.amazon, .linkedin],
            prompt: "Design a time-based key-value store: `set(key, value, timestamp)` stores a value at a given timestamp; `get(key, timestamp)` returns the value set at the largest timestamp ≤ the given one (or empty string if none).",
            constraints: ["timestamps are strictly increasing per key across set() calls", "up to 2 × 10^5 total calls"],
            examples: [
                Example(input: "set(\"foo\",\"bar\",1); get(\"foo\",1) -> \"bar\"; get(\"foo\",4) -> \"bar\"", output: "see explanation", explanation: nil)
            ],
            hints: [
                "Since timestamps for a given key only ever increase, each key's history of (timestamp, value) pairs is naturally sorted -- no extra sorting needed.",
                "'Largest timestamp ≤ target' in a sorted list is a classic binary search (upper-bound-minus-one) pattern."
            ],
            approaches: [
                Approach(name: "Per-key sorted list + binary search", summary: "Store each key's (timestamp, value) history in append order (already sorted); binary search for the query.",
                         timeComplexity: "O(log n) per get, O(1) amortized per set", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected solution.",
                         steps: ["set(key, value, ts): store[key].append((ts, value))",
                                  "get(key, ts): binary search store[key] for the rightmost entry with timestamp ≤ ts",
                                  "Return its value, or \"\" if none exists"])
            ],
            starterCode: [
                .swift: "final class TimeMap {\n    init() {\n        // Write your solution here\n    }\n    func set(_ key: String, _ value: String, _ timestamp: Int) {\n    }\n    func get(_ key: String, _ timestamp: Int) -> String {\n        return \"\"\n    }\n}\n",
                .python: "class TimeMap:\n    def __init__(self):\n        pass\n    def set(self, key: str, value: str, timestamp: int) -> None:\n        pass\n    def get(self, key: str, timestamp: int) -> str:\n        return \"\"\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "word-search-ii",
            title: "Word Search II",
            difficulty: .hard,
            topics: [.backtracking, .tries],
            companies: [.amazon, .google, .uber],
            prompt: "Given an `m x n` grid of characters and a list of words, return all words from the list that can be formed by a path of adjacent (up/down/left/right) cells, without reusing a cell within one word.",
            constraints: ["1 ≤ m, n ≤ 12", "1 ≤ words.count ≤ 3 × 10^4"],
            examples: [
                Example(input: "board + words = [\"oath\",\"pea\",\"eat\",\"rain\"]", output: "[\"oath\",\"eat\"]", explanation: nil)
            ],
            hints: [
                "Running a separate word-search DFS from scratch for every single word is far too slow when there are thousands of words.",
                "Build a Trie out of ALL the words first, then do ONE combined DFS over the board, walking the Trie alongside your path -- this lets many words share the same search work and lets you prune branches the instant no word could match.",
                "Mark a word as found in the Trie node itself once discovered, and prune that branch afterward to avoid duplicate work."
            ],
            approaches: [
                Approach(name: "Trie + single combined backtracking search", summary: "Build a Trie of all target words; DFS from every board cell, following Trie edges, collecting complete words as you go.",
                         timeComplexity: "O(m · n · 4^L) worst case, L = longest word", spaceComplexity: "O(total characters across words)",
                         whenToUse: "The standard, expected optimal approach -- turns a hard problem manageable at scale.",
                         steps: ["Build a Trie from all words, marking word-end nodes with the full word",
                                  "For each starting cell: DFS, at each step following the Trie edge matching the current board character",
                                  "If a Trie node marks a complete word, record it (and avoid re-recording)",
                                  "Backtrack (unmark visited cell) after exploring"])
            ],
            starterCode: [
                .swift: "func findWords(_ board: [[Character]], _ words: [String]) -> [String] {\n    // Write your solution here\n    return []\n}\n",
                .python: "def find_words(board: list[list[str]], words: list[str]) -> list[str]:\n    # Write your solution here\n    return []\n"
            ],
            followUp: nil
        ),

        Problem(
            id: "basic-calculator",
            title: "Basic Calculator",
            difficulty: .hard,
            topics: [.stack],
            companies: [.amazon, .google],
            prompt: "Implement a basic calculator to evaluate a string expression containing non-negative integers, `+`, `-`, parentheses, and spaces (no multiplication/division).",
            constraints: ["1 ≤ s.length ≤ 3 × 10^5"],
            examples: [
                Example(input: "s = \"(1+(4+5+2)-3)+(6+8)\"", output: "23", explanation: nil)
            ],
            hints: [
                "Parentheses mean you sometimes need to 'pause' the current running total and sign while you evaluate a nested expression -- that's a natural fit for a stack.",
                "Track a running result and a 'current sign' (+1 or -1) as you scan left to right; on '(', push both onto a stack and reset; on ')', pop and combine.",
                "Numbers can be multi-digit, so accumulate digits until you hit a non-digit character."
            ],
            approaches: [
                Approach(name: "Single pass with a sign/result stack", summary: "Scan once, maintaining a running result and sign, pushing/popping state at parentheses.",
                         timeComplexity: "O(n)", spaceComplexity: "O(n) worst case (nested parens)",
                         whenToUse: "The standard, expected solution -- avoids building a full expression tree.",
                         steps: ["result = 0, sign = 1, stack = []",
                                  "On a digit: accumulate the full number, then result += sign * number",
                                  "On '+': sign = 1. On '-': sign = -1",
                                  "On '(': push (result, sign) onto stack; reset result = 0, sign = 1",
                                  "On ')': pop (prevResult, prevSign); result = prevResult + prevSign * result"])
            ],
            starterCode: [
                .swift: "func calculate(_ s: String) -> Int {\n    // Write your solution here\n    return 0\n}\n",
                .python: "def calculate(s: str) -> int:\n    # Write your solution here\n    return 0\n"
            ],
            followUp: "How would you extend this to support multiplication and division too?"
        ),

        Problem(
            id: "cheapest-flights-within-k-stops",
            title: "Cheapest Flights Within K Stops",
            difficulty: .hard,
            topics: [.graphs, .dynamicProgramming],
            companies: [.uber, .amazon],
            prompt: "Given `n` cities, flight routes with prices, a source, a destination, and a max number of stops `k`, find the cheapest price from source to destination using at most k+1 flights, or -1 if impossible.",
            constraints: ["1 ≤ n ≤ 100", "0 ≤ k ≤ n-1"],
            examples: [
                Example(input: "n = 4, flights = [[0,1,100],[1,2,100],[2,0,100],[1,3,600],[2,3,200]], src=0, dst=3, k=1",
                        output: "700", explanation: "0 -> 1 -> 3 costs 100+600=700 within 1 stop.")
            ],
            hints: [
                "Plain Dijkstra doesn't directly respect the 'at most k stops' limit -- the cheapest overall path might use too many stops.",
                "Think of it as Bellman-Ford limited to k+1 rounds: each round, relax all edges using ONLY distances from the previous round (not updates made within the same round), so you never use more than that many flights.",
                "Using a snapshot/copy of distances at the start of each round is important -- relaxing in place can let a path 'sneak in' an extra hop."
            ],
            approaches: [
                Approach(name: "Bellman-Ford limited to k+1 rounds", summary: "Relax all edges for exactly k+1 rounds, using a frozen snapshot of the previous round's distances each time.",
                         timeComplexity: "O(k · E)", spaceComplexity: "O(n)",
                         whenToUse: "The standard, expected approach for a stop-limited shortest path.",
                         steps: ["dist = array of n infinities; dist[src] = 0",
                                  "Repeat k+1 times: snapshot = copy of dist",
                                  "For each edge (u, v, price): if snapshot[u] + price < dist[v]: dist[v] = snapshot[u] + price",
                                  "Return dist[dst] if finite, else -1"])
            ],
            starterCode: [
                .swift: "func findCheapestPrice(_ n: Int, _ flights: [[Int]], _ src: Int, _ dst: Int, _ k: Int) -> Int {\n    // Write your solution here\n    return -1\n}\n",
                .python: "def find_cheapest_price(n: int, flights: list[list[int]], src: int, dst: int, k: int) -> int:\n    # Write your solution here\n    return -1\n"
            ],
            followUp: nil
        )

    ]

    static func problem(id: String) -> Problem? {
        all.first { $0.id == id }
    }
}
