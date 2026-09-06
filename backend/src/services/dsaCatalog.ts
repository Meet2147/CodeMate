export type DsaDifficulty = "easy" | "medium" | "hard";
export type DsaLanguage = "python3" | "cpp";

export interface DsaTestCase {
  input: string;
  expected: string;
}

export interface DsaProblem {
  id: string;
  title: string;
  difficulty: DsaDifficulty;
  topic: string;
  prompt: string;
  inputFormat: string;
  outputFormat: string;
  constraints: string[];
  examples: Array<{ input: string; output: string }>;
  starter: Record<DsaLanguage, string>;
  publicTests: DsaTestCase[];
  hiddenTests: DsaTestCase[];
}

const pyGeneric = `import sys\n\ndef solve(lines):\n    # TODO: implement\n    return ""\n\nif __name__ == "__main__":\n    data = [line.rstrip("\\n") for line in sys.stdin.readlines()]\n    ans = solve(data)\n    if ans is None:\n        ans = ""\n    print(ans)\n`;

const cppGeneric = `#include <bits/stdc++.h>\nusing namespace std;\n\nstring solve(const vector<string>& lines) {\n    // TODO: implement\n    return \"\";\n}\n\nint main() {\n    ios::sync_with_stdio(false);\n    cin.tie(nullptr);\n\n    vector<string> lines;\n    string line;\n    while (getline(cin, line)) lines.push_back(line);\n\n    cout << solve(lines);\n    return 0;\n}\n`;

const coreDsaProblems: DsaProblem[] = [
  {
    id: "two-sum-sorted",
    title: "Two Sum (Sorted Array)",
    difficulty: "easy",
    topic: "Arrays",
    prompt:
      "Given a sorted integer array and a target, return the 0-based indices of the two numbers such that they add up to the target. Exactly one valid answer exists.",
    inputFormat: "Line 1: n\nLine 2: n integers\nLine 3: target",
    outputFormat: "Print two indices i and j separated by a space.",
    constraints: ["2 <= n <= 1e5", "Array is sorted in non-decreasing order"],
    examples: [{ input: "4\n2 7 11 15\n9", output: "0 1" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "4\n2 7 11 15\n9", expected: "0 1" },
      { input: "5\n1 2 3 4 6\n6", expected: "1 3" }
    ],
    hiddenTests: [
      { input: "6\n1 3 4 5 7 11\n12", expected: "2 4" },
      { input: "7\n-5 -3 -1 0 2 4 9\n1", expected: "2 4" }
    ]
  },
  {
    id: "valid-parentheses",
    title: "Valid Parentheses",
    difficulty: "easy",
    topic: "Stack",
    prompt: "Given a string of brackets (), {}, [] determine if it is valid.",
    inputFormat: "Line 1: bracket string",
    outputFormat: "Print true or false in lowercase.",
    constraints: ["1 <= length <= 1e5"],
    examples: [{ input: "()[]{}", output: "true" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "()[]{}", expected: "true" },
      { input: "([{}])", expected: "true" }
    ],
    hiddenTests: [
      { input: "(]", expected: "false" },
      { input: "([)]", expected: "false" }
    ]
  },
  {
    id: "binary-search",
    title: "Binary Search",
    difficulty: "easy",
    topic: "Binary Search",
    prompt: "Return the index of target in a sorted array, or -1 if not found.",
    inputFormat: "Line 1: n\nLine 2: n integers\nLine 3: target",
    outputFormat: "Print index or -1.",
    constraints: ["1 <= n <= 1e5"],
    examples: [{ input: "6\n-1 0 3 5 9 12\n9", output: "4" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "6\n-1 0 3 5 9 12\n9", expected: "4" },
      { input: "6\n-1 0 3 5 9 12\n2", expected: "-1" }
    ],
    hiddenTests: [
      { input: "5\n1 3 5 7 9\n1", expected: "0" },
      { input: "5\n1 3 5 7 9\n9", expected: "4" }
    ]
  },
  {
    id: "best-time-stock",
    title: "Best Time to Buy and Sell Stock",
    difficulty: "easy",
    topic: "Greedy",
    prompt: "Given daily prices, return max profit from one buy and one sell.",
    inputFormat: "Line 1: n\nLine 2: n integers",
    outputFormat: "Print max profit integer.",
    constraints: ["1 <= n <= 2e5"],
    examples: [{ input: "6\n7 1 5 3 6 4", output: "5" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "6\n7 1 5 3 6 4", expected: "5" },
      { input: "5\n7 6 4 3 1", expected: "0" }
    ],
    hiddenTests: [
      { input: "8\n2 4 1 9 3 11 2 10", expected: "10" },
      { input: "4\n1 2 3 4", expected: "3" }
    ]
  },
  {
    id: "longest-substring-no-repeat",
    title: "Longest Substring Without Repeating Characters",
    difficulty: "medium",
    topic: "Sliding Window",
    prompt: "Given a string, return the length of the longest substring without repeating characters.",
    inputFormat: "Line 1: string",
    outputFormat: "Print integer length.",
    constraints: ["0 <= length <= 1e5"],
    examples: [{ input: "abcabcbb", output: "3" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "abcabcbb", expected: "3" },
      { input: "bbbbb", expected: "1" }
    ],
    hiddenTests: [
      { input: "pwwkew", expected: "3" },
      { input: "", expected: "0" }
    ]
  },
  {
    id: "product-except-self",
    title: "Product of Array Except Self",
    difficulty: "medium",
    topic: "Arrays",
    prompt:
      "Return an array output where output[i] is the product of all elements except nums[i], without using division.",
    inputFormat: "Line 1: n\nLine 2: n integers",
    outputFormat: "Print n integers separated by space.",
    constraints: ["2 <= n <= 1e5"],
    examples: [{ input: "4\n1 2 3 4", output: "24 12 8 6" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "4\n1 2 3 4", expected: "24 12 8 6" },
      { input: "5\n-1 1 0 -3 3", expected: "0 0 9 0 0" }
    ],
    hiddenTests: [
      { input: "3\n2 3 5", expected: "15 10 6" },
      { input: "4\n0 4 0 2", expected: "0 0 0 0" }
    ]
  },
  {
    id: "number-of-islands",
    title: "Number of Islands",
    difficulty: "medium",
    topic: "Graph",
    prompt:
      "Given a grid of 0s and 1s, count the number of connected islands (4-directionally connected).",
    inputFormat: "Line 1: r c\nNext r lines: string of 0/1 of length c",
    outputFormat: "Print number of islands.",
    constraints: ["1 <= r,c <= 200"],
    examples: [{ input: "4 5\n11000\n11000\n00100\n00011", output: "3" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "4 5\n11000\n11000\n00100\n00011", expected: "3" },
      { input: "3 3\n111\n010\n111", expected: "1" }
    ],
    hiddenTests: [
      { input: "2 2\n00\n00", expected: "0" },
      { input: "3 4\n1001\n0000\n1001", expected: "4" }
    ]
  },
  {
    id: "coin-change",
    title: "Coin Change",
    difficulty: "medium",
    topic: "Dynamic Programming",
    prompt: "Given coin values and amount, return minimum coins needed, or -1 if impossible.",
    inputFormat: "Line 1: n\nLine 2: n integers (coins)\nLine 3: amount",
    outputFormat: "Print minimum coins as integer.",
    constraints: ["1 <= n <= 30", "0 <= amount <= 1e4"],
    examples: [{ input: "3\n1 2 5\n11", output: "3" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "3\n1 2 5\n11", expected: "3" },
      { input: "1\n2\n3", expected: "-1" }
    ],
    hiddenTests: [
      { input: "4\n2 5 10 1\n27", expected: "4" },
      { input: "2\n3 7\n0", expected: "0" }
    ]
  },
  {
    id: "median-two-sorted",
    title: "Median of Two Sorted Arrays",
    difficulty: "hard",
    topic: "Binary Search",
    prompt: "Find the median of two sorted arrays.",
    inputFormat: "Line 1: n m\nLine 2: n integers\nLine 3: m integers",
    outputFormat: "Print median (integer or decimal with .5 when needed).",
    constraints: ["0 <= n,m <= 1e5", "n + m >= 1"],
    examples: [{ input: "2 2\n1 2\n3 4", output: "2.5" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "2 2\n1 2\n3 4", expected: "2.5" },
      { input: "2 1\n1 3\n2", expected: "2" }
    ],
    hiddenTests: [
      { input: "1 3\n100\n1 2 3", expected: "2.5" },
      { input: "4 4\n1 2 3 4\n5 6 7 8", expected: "4.5" }
    ]
  },
  {
    id: "edit-distance",
    title: "Edit Distance",
    difficulty: "hard",
    topic: "Dynamic Programming",
    prompt:
      "Given two words, return the minimum number of operations required to convert one word to the other (insert, delete, replace).",
    inputFormat: "Line 1: word1\nLine 2: word2",
    outputFormat: "Print minimum operations as integer.",
    constraints: ["0 <= len(word1), len(word2) <= 500"],
    examples: [{ input: "horse\nros", output: "3" }],
    starter: { python3: pyGeneric, cpp: cppGeneric },
    publicTests: [
      { input: "horse\nros", expected: "3" },
      { input: "intention\nexecution", expected: "5" }
    ],
    hiddenTests: [
      { input: "\nabc", expected: "3" },
      { input: "abc\nabc", expected: "0" }
    ]
  }
];

const variantDsaProblems: DsaProblem[] = coreDsaProblems.flatMap((problem) =>
  Array.from({ length: 4 }, (_, index) => {
    const variantNo = index + 1;
    return {
      ...problem,
      id: `${problem.id}-v${variantNo}`,
      title: `${problem.title} (Variant ${variantNo})`
    };
  })
);

export const dsaProblems: DsaProblem[] = [...coreDsaProblems, ...variantDsaProblems];

export function getProblemById(problemId: string): DsaProblem | null {
  return dsaProblems.find((problem) => problem.id === problemId) || null;
}
