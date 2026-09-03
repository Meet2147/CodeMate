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
            companies: [.amazon, .google, .apple, .microsoft],
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
            companies: [.amazon, .microsoft, .google],
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
            companies: [.amazon, .microsoft, .apple],
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
            companies: [.google, .amazon, .microsoft],
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
            companies: [.amazon, .google, .microsoft],
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
            companies: [.google, .amazon],
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
            companies: [.amazon, .google, .microsoft],
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
            companies: [.amazon, .apple, .microsoft],
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
            companies: [.amazon, .microsoft],
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
            companies: [.amazon, .google, .microsoft, .apple],
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
            companies: [.amazon, .google, .microsoft],
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
            companies: [.amazon, .apple, .microsoft],
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
            companies: [.amazon, .google],
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
            companies: [.amazon, .microsoft, .google],
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
            companies: [.amazon, .google, .apple],
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
            companies: [.google, .amazon, .microsoft],
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
            companies: [.google, .amazon, .microsoft],
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
        )
    ]

    static func problem(id: String) -> Problem? {
        all.first { $0.id == id }
    }
}
