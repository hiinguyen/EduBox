// Demo exam content for the seed. Correct answers are the seed author's keys for the demo only.
// Mirrors the 25 questions of the exam fixture; the fixture itself is replaced by DB reads later.
export interface SeedQuestion {
  readonly number: number;
  readonly levelLabel: string;
  readonly points: number;
  readonly prompt: readonly { readonly kind: "text" | "math" | "code"; readonly text: string }[];
  readonly options: readonly [string, string, string, string];
  readonly correctLabel: "A" | "B" | "C" | "D";
  readonly figure: unknown;
}

export const SEED_QUESTIONS: readonly SeedQuestion[] = [
  {
    number: 1,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Hàm số ",
      },
      {
        kind: "math",
        text: "y = x³ - 3x",
      },
      {
        kind: "text",
        text: " đồng biến trên khoảng nào sau đây?",
      },
    ],
    options: ["(-∞; -1)", "(-1; 1)", "(0; 2)", "(-2; 0)"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 2,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Giá trị cực đại của hàm số ",
      },
      {
        kind: "math",
        text: "y = x³ - 3x + 2",
      },
      {
        kind: "text",
        text: " bằng bao nhiêu?",
      },
    ],
    options: ["0", "2", "4", "-1"],
    correctLabel: "C",
    figure: null,
  },
  {
    number: 3,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Tiệm cận ngang của đồ thị hàm số ",
      },
      {
        kind: "math",
        text: "y = (2x + 1)/(x - 1)",
      },
      {
        kind: "text",
        text: " là đường thẳng nào?",
      },
    ],
    options: ["y = 2", "y = 1", "x = 1", "x = 2"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 4,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Số điểm cực trị của hàm số ",
      },
      {
        kind: "math",
        text: "y = x⁴ - 2x² + 3",
      },
      {
        kind: "text",
        text: " là bao nhiêu?",
      },
    ],
    options: ["1", "2", "3", "4"],
    correctLabel: "C",
    figure: null,
  },
  {
    number: 5,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Giá trị nhỏ nhất của hàm số ",
      },
      {
        kind: "math",
        text: "y = x² - 4x + 5",
      },
      {
        kind: "text",
        text: " trên ",
      },
      {
        kind: "math",
        text: "ℝ",
      },
      {
        kind: "text",
        text: " bằng bao nhiêu?",
      },
    ],
    options: ["0", "1", "2", "5"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 6,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Tập xác định của hàm số ",
      },
      {
        kind: "math",
        text: "y = log₂(x - 3)",
      },
      {
        kind: "text",
        text: " là tập nào sau đây?",
      },
    ],
    options: ["(3; +∞)", "[3; +∞)", "(-∞; 3)", "ℝ \\ {3}"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 7,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Đạo hàm của hàm số ",
      },
      {
        kind: "math",
        text: "y = eˣ + x²",
      },
      {
        kind: "text",
        text: " là hàm số nào sau đây?",
      },
    ],
    options: ["eˣ + 2x", "eˣ + x", "xeˣ⁻¹ + 2x", "eˣ + 2"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 8,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Nghiệm của phương trình ",
      },
      {
        kind: "math",
        text: "2ˣ = 8",
      },
      {
        kind: "text",
        text: " là bao nhiêu?",
      },
    ],
    options: ["2", "3", "4", "8"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 9,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Giá trị của tích phân ",
      },
      {
        kind: "math",
        text: "∫₀¹ 2x dx",
      },
      {
        kind: "text",
        text: " bằng bao nhiêu?",
      },
    ],
    options: ["0", "1", "2", "1/2"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 10,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Hàm số ",
      },
      {
        kind: "math",
        text: "y = -x³ + 3x² - 1",
      },
      {
        kind: "text",
        text: " nghịch biến trên khoảng nào sau đây?",
      },
    ],
    options: ["(0; 2)", "(2; +∞)", "(-∞; 2)", "(-1; 1)"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 11,
    levelLabel: "Vận dụng",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Có bao nhiêu giá trị nguyên của ",
      },
      {
        kind: "math",
        text: "m",
      },
      {
        kind: "text",
        text: " để hàm số ",
      },
      {
        kind: "math",
        text: "y = x³ - 3x² + m",
      },
      {
        kind: "text",
        text: " có hai điểm cực trị nằm về hai phía trục hoành ",
      },
      {
        kind: "code",
        text: "(-5 < m < 5)",
      },
      {
        kind: "text",
        text: "?",
      },
    ],
    options: ["2", "3", "4", "5"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 12,
    levelLabel: "Vận dụng cao",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Cho hàm số ",
      },
      {
        kind: "math",
        text: "y = f(x)",
      },
      {
        kind: "text",
        text: " liên tục trên ",
      },
      {
        kind: "math",
        text: "ℝ",
      },
      {
        kind: "text",
        text: " và có bảng xét dấu đạo hàm ",
      },
      {
        kind: "math",
        text: "f'(x)",
      },
      {
        kind: "text",
        text: " cùng đồ thị được mô phỏng như hình bên dưới. Có bao nhiêu giá trị nguyên của tham số ",
      },
      {
        kind: "math",
        text: "m",
      },
      {
        kind: "text",
        text: " thuộc đoạn ",
      },
      {
        kind: "code",
        text: "[-10; 10]",
      },
      {
        kind: "text",
        text: " để hàm số ",
      },
      {
        kind: "math",
        text: "g(x) = f(x² - 2x + m)",
      },
      {
        kind: "text",
        text: " có đúng 5 điểm cực trị?",
      },
    ],
    options: ["3 giá trị", "4 giá trị", "5 giá trị", "6 giá trị"],
    correctLabel: "B",
    figure: {
      kind: "derivative-graph",
      title: "Đồ thị đạo hàm f'(x) trên mặt phẳng Oxy",
      notesTitle: "Đặc tính đồ thị đã cho:",
      notes: [
        [
          {
            kind: "text",
            text: "• ",
          },
          {
            kind: "math",
            text: "f'(x) = 0",
          },
          {
            kind: "text",
            text: " có 3 nghiệm phân biệt: ",
          },
          {
            kind: "code",
            text: "x₁ = -1, x₂ = 1, x₃ = 3",
          },
        ],
        [
          {
            kind: "text",
            text: "• Dấu của ",
          },
          {
            kind: "math",
            text: "f'(x)",
          },
          {
            kind: "text",
            text: " đan dấu qua cả 3 nghiệm thực.",
          },
        ],
        [
          {
            kind: "text",
            text: "• Hàm hợp: ",
          },
          {
            kind: "math",
            text: "u(x) = x² - 2x + m",
          },
          {
            kind: "text",
            text: " có đỉnh tại ",
          },
          {
            kind: "code",
            text: "x = 1",
          },
          {
            kind: "text",
            text: ".",
          },
        ],
      ],
    },
  },
  {
    number: 13,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Cho cấp số cộng ",
      },
      {
        kind: "math",
        text: "(uₙ)",
      },
      {
        kind: "text",
        text: " có ",
      },
      {
        kind: "math",
        text: "u₁ = 3",
      },
      {
        kind: "text",
        text: " và công sai ",
      },
      {
        kind: "math",
        text: "d = 2",
      },
      {
        kind: "text",
        text: ". Giá trị của ",
      },
      {
        kind: "math",
        text: "u₁₀",
      },
      {
        kind: "text",
        text: " bằng bao nhiêu?",
      },
    ],
    options: ["19", "21", "23", "25"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 14,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Thể tích khối chóp có diện tích đáy ",
      },
      {
        kind: "math",
        text: "B",
      },
      {
        kind: "text",
        text: " và chiều cao ",
      },
      {
        kind: "math",
        text: "h",
      },
      {
        kind: "text",
        text: " được tính theo công thức nào?",
      },
    ],
    options: ["V = B·h", "V = (1/3)B·h", "V = (1/2)B·h", "V = 3B·h"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 15,
    levelLabel: "Vận dụng",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Cho hình lăng trụ đứng có đáy là tam giác đều cạnh ",
      },
      {
        kind: "math",
        text: "a",
      },
      {
        kind: "text",
        text: " và chiều cao ",
      },
      {
        kind: "math",
        text: "2a",
      },
      {
        kind: "text",
        text: ". Thể tích khối lăng trụ bằng bao nhiêu?",
      },
    ],
    options: ["a³√3/2", "a³√3/4", "a³√3", "2a³√3"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 16,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Trong không gian ",
      },
      {
        kind: "math",
        text: "Oxyz",
      },
      {
        kind: "text",
        text: ", khoảng cách từ điểm ",
      },
      {
        kind: "math",
        text: "A(1; 2; 2)",
      },
      {
        kind: "text",
        text: " đến gốc tọa độ bằng bao nhiêu?",
      },
    ],
    options: ["2", "3", "5", "9"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 17,
    levelLabel: "Vận dụng",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Gieo một con xúc xắc cân đối hai lần. Xác suất để tổng số chấm bằng 7 là bao nhiêu?",
      },
    ],
    options: ["1/6", "1/9", "5/36", "7/36"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 18,
    levelLabel: "Vận dụng",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Số nghiệm thực của phương trình ",
      },
      {
        kind: "math",
        text: "f(x) = 2",
      },
      {
        kind: "text",
        text: " với ",
      },
      {
        kind: "math",
        text: "f(x) = x³ - 3x + 4",
      },
      {
        kind: "text",
        text: " là bao nhiêu?",
      },
    ],
    options: ["0", "1", "2", "3"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 19,
    levelLabel: "Vận dụng cao",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Có bao nhiêu giá trị nguyên của ",
      },
      {
        kind: "math",
        text: "m",
      },
      {
        kind: "text",
        text: " để phương trình ",
      },
      {
        kind: "math",
        text: "x³ - 3x = m",
      },
      {
        kind: "text",
        text: " có ba nghiệm thực phân biệt?",
      },
    ],
    options: ["1", "2", "3", "4"],
    correctLabel: "C",
    figure: null,
  },
  {
    number: 20,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Số phức ",
      },
      {
        kind: "math",
        text: "z = 3 - 4i",
      },
      {
        kind: "text",
        text: " có môđun bằng bao nhiêu?",
      },
    ],
    options: ["1", "5", "7", "25"],
    correctLabel: "C",
    figure: null,
  },
  {
    number: 21,
    levelLabel: "Nhận biết",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Nguyên hàm của hàm số ",
      },
      {
        kind: "math",
        text: "f(x) = cos x",
      },
      {
        kind: "text",
        text: " là hàm số nào sau đây?",
      },
    ],
    options: ["sin x + C", "-sin x + C", "cos x + C", "-cos x + C"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 22,
    levelLabel: "Vận dụng",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Diện tích hình phẳng giới hạn bởi ",
      },
      {
        kind: "math",
        text: "y = x²",
      },
      {
        kind: "text",
        text: " và ",
      },
      {
        kind: "math",
        text: "y = x",
      },
      {
        kind: "text",
        text: " bằng bao nhiêu?",
      },
    ],
    options: ["1/6", "1/3", "1/2", "1"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 23,
    levelLabel: "Vận dụng cao",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Cho hàm số ",
      },
      {
        kind: "math",
        text: "f(x)",
      },
      {
        kind: "text",
        text: " có ",
      },
      {
        kind: "math",
        text: "f'(x) = (x - 1)(x + 2)²",
      },
      {
        kind: "text",
        text: ". Hàm số đã cho có bao nhiêu điểm cực trị?",
      },
    ],
    options: ["0", "1", "2", "3"],
    correctLabel: "A",
    figure: null,
  },
  {
    number: 24,
    levelLabel: "Thông hiểu",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Mặt cầu có bán kính ",
      },
      {
        kind: "math",
        text: "R = 3",
      },
      {
        kind: "text",
        text: " có diện tích bằng bao nhiêu?",
      },
    ],
    options: ["9π", "18π", "36π", "108π"],
    correctLabel: "B",
    figure: null,
  },
  {
    number: 25,
    levelLabel: "Vận dụng",
    points: 0.4,
    prompt: [
      {
        kind: "text",
        text: "Giá trị lớn nhất của hàm số ",
      },
      {
        kind: "math",
        text: "y = x + 4/x",
      },
      {
        kind: "text",
        text: " trên đoạn ",
      },
      {
        kind: "code",
        text: "[1; 4]",
      },
      {
        kind: "text",
        text: " bằng bao nhiêu?",
      },
    ],
    options: ["4", "5", "6", "8"],
    correctLabel: "C",
    figure: null,
  },
] as const;
