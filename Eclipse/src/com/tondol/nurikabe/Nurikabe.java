package com.tondol.nurikabe;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Stack;

public class Nurikabe {
	public static final int U = 0;
	public static final int W = Integer.MIN_VALUE;
	public static final int B = Integer.MAX_VALUE;

	private Matrix mBoard = null;
	private Matrix mGroup = null;
	private Matrix mGroupWhite = null;
	private Matrix mGroupBlack = null;
	private Map<Integer, List<SummaryEntry>> mSummary = null;
	private Map<Integer, List<SummaryEntry>> mSummaryWhite = null;
	private Map<Integer, List<SummaryEntry>> mSummaryBlack = null;

	public Nurikabe(Matrix board) {
		mBoard = board;
	}

	/**
	 * GroupFunction / GroupPair / SummaryEntry
	 */
	private interface GroupFunction {
		public int f(int value);
	}
	private static class GroupPair {
		int v1;
		int v2;

		public GroupPair(int v1, int v2) {
			this.v1 = v1;
			this.v2 = v2;
		}
		@Override
		public String toString() {
			return String.format("{ v1=%d, v2=%d }", v1, v2);
		}
	}
	private static class SummaryEntry {
		int x;
		int y;
		int value;

		public SummaryEntry(int x, int y, int value) {
			this.x = x;
			this.y = y;
			this.value = value;
		}
		@Override
		public String toString() {
			String s = Utils.valueToString(value);
			return String.format("{ x=%d, y=%d, value=%s }", x, y, s);
		}
	}
	private static class Position {
		int x;
		int y;

		public Position(int x, int y) {
			this.x = x;
			this.y = y;
		}
		@Override
		public String toString() {
			return String.format("{ x=%d, y=%d }", x, y);
		}
	}

	/**
	 * Utilities
	 */
	private boolean isWhite(int value) {
		return value == W;
	}
	private boolean isBlack(int value) {
		return value == B;
	}
	private boolean isNumber(int value) {
		return value >= 1 && value <= 9;
	}
	private boolean isFilled(int value) {
		return isWhite(value) || isBlack(value) || isNumber(value);
	}
	private int getKind(int value) {
		if (isWhite(value) || isNumber(value)) {
			return 1;
		} else if (isBlack(value)) {
			return 2;
		} else {
			return 0;
		}
	}
	private int getKindWhite(int value) {
		if (!isFilled(value)) {
			return getKind(Nurikabe.W);
		} else {
			return getKind(value);
		}
	}
	private int getKindBlack(int value) {
		if (!isFilled(value)) {
			return getKind(Nurikabe.B);
		} else {
			return getKind(value);
		}
	}
	private void invalidate() {
		mGroup = mGroupWhite = mGroupBlack = null;
		mSummary = mSummaryWhite = mSummaryBlack = null;
	}

	/**
	 * Group
	 */
	private Map<Integer, Integer> getGroupMap(List<GroupPair> pairs) {
		int next_index = 0;
		Map<Integer, Integer> map = new HashMap<Integer, Integer>();

		for (GroupPair pair : pairs) {
			SafeInteger o1 = new SafeInteger(map.get(pair.v1));
			SafeInteger o2 = new SafeInteger(map.get(pair.v2));
			int index1 = o1.intValue(-1);
			int index2 = o2.intValue(-1);

			if (index1 < 0 && index2 < 0) {
				map.put(pair.v1, next_index);
				map.put(pair.v2, next_index);
				next_index++;
			} else if (index1 >= 0 && index2 < 0) {
				map.put(pair.v2, index1);
			} else if (index1 < 0 && index2 >= 0) {
				map.put(pair.v1, index2);
			} else if (index1 != index2) {
				int min = Math.min(index1, index2);
				int max = Math.max(index1, index2);
				for (Map.Entry<Integer, Integer> entry : map.entrySet()) {
					int key = entry.getKey();
					int value = entry.getValue();
					if (value == max) {
						map.put(key, min);
					} else if (value > max) {
						map.put(key, value - 1);
					}
				}
			}
		}

		return map;
	}
	private Matrix doGroup(GroupFunction func) {
		final int w = mBoard.getW();
		final int h = mBoard.getH();

		int next_index = 0;
		Matrix matrix = new Matrix(w, h);
		List<GroupPair> pairs = new ArrayList<GroupPair>();

		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				boolean equals1 = i > 0 && func.f(mBoard.get(i - 1, j)) == func.f(mBoard.get(i, j));
				boolean equals2 = j > 0 && func.f(mBoard.get(i, j - 1)) == func.f(mBoard.get(i, j));

				if (!equals1 && !equals2) {
					matrix.put(i, j, next_index);
					pairs.add(new GroupPair(next_index, next_index));
					next_index++;
				} else if (equals1 && !equals2) {
					matrix.put(i, j, matrix.get(i - 1, j));
				} else if (!equals1 && equals2) {
					matrix.put(i, j, matrix.get(i, j - 1));
				} else {
					int min = Math.min(matrix.get(i - 1, j), matrix.get(i, j - 1));
					int max = Math.max(matrix.get(i - 1, j), matrix.get(i, j - 1));
					matrix.put(i, j, min);
					pairs.add(new GroupPair(min, max));
				}
			}
		}

		Map<Integer, Integer> map = getGroupMap(pairs);

		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				matrix.put(i, j, map.get(matrix.get(i, j)));
			}
		}

		return matrix;
	}
	public Matrix group() {
		if (mGroup != null) {
			return mGroup;
		}

		return mGroup = doGroup(new GroupFunction() {
			@Override
			public int f(int value) {
				return getKind(value);
			}
		});
	}
	public Matrix groupWhite() {
		if (mGroupWhite != null) {
			return mGroupWhite;
		}

		return mGroupWhite = doGroup(new GroupFunction() {
			@Override
			public int f(int value) {
				return getKindWhite(value);
			}
		});
	}
	public Matrix groupBlack() {
		if (mGroupBlack != null) {
			return mGroupBlack;
		}

		return mGroupBlack = doGroup(new GroupFunction() {
			@Override
			public int f(int value) {
				return getKindBlack(value);
			}
		});
	}

	/**
	 * Summary
	 */
	public Map<Integer, List<SummaryEntry>> doSummary(GroupFunction func) {
		final int w = mBoard.getW();
		final int h = mBoard.getH();

		Matrix group = doGroup(func);
		Map<Integer, List<SummaryEntry>> map = new HashMap<Integer, List<SummaryEntry>>();

		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				int index = group.get(i, j);
				if (!map.containsKey(index)) {
					map.put(index, new ArrayList<SummaryEntry>());
				}

				int value = mBoard.get(i, j);
				SummaryEntry entry = new SummaryEntry(j, i, value);
				map.get(index).add(entry);
			}
		}

		return map;
	}
	public Map<Integer, List<SummaryEntry>> summary() {
		if (mSummary != null) {
			return mSummary;
		}

		return mSummary = doSummary(new GroupFunction() {
			@Override
			public int f(int value) {
				return getKind(value);
			}
		});
	}
	public Map<Integer, List<SummaryEntry>> summaryWhite() {
		if (mSummaryWhite != null) {
			return mSummaryWhite;
		}

		return mSummaryWhite = doSummary(new GroupFunction() {
			@Override
			public int f(int value) {
				return getKindWhite(value);
			}
		});
	}
	public Map<Integer, List<SummaryEntry>> summaryBlack() {
		if (mSummaryBlack != null) {
			return mSummaryBlack;
		}

		return mSummaryBlack = doSummary(new GroupFunction() {
			@Override
			public int f(int value) {
				return getKindBlack(value);
			}
		});
	}

	/**
	 * Check
	 */
	private boolean notContains2X2() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();

		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				if (i > 0 && j > 0 &&
						mBoard.get(i, j) == Nurikabe.B &&
						mBoard.get(i - 0, j - 0) == mBoard.get(i - 0, j - 1) &&
						mBoard.get(i - 0, j - 1) == mBoard.get(i - 1, j - 0) &&
						mBoard.get(i - 1, j - 0) == mBoard.get(i - 1, j - 1)) {
					return false;
				}
			}
		}

		return true;
	}
	private boolean isContinuous() {
		int count = 0;
		Map<Integer, List<SummaryEntry>> summary = summary();

		// 黒のあるエリア数を数える
		for (List<SummaryEntry> entries : summary.values()) {
			for (SummaryEntry entry : entries) {
				if (isBlack(entry.value)) {
					count++;
					break;
				}
			}
		}

		return count == 1;
	}
	private boolean isValidCombination() {
		Map<Integer, List<SummaryEntry>> summary = summary();

		for (List<SummaryEntry> entries : summary.values()) {
			int number = 0;
			int countW = 0;
			int countN = 0;
			int countB = 0;

			// 各マスを数える・数字を検索する
			for (SummaryEntry entry : entries) {
				if (isWhite(entry.value)) {
					countW++;
				} else if (isNumber(entry.value)) {
					number = entry.value;
					countN++;
				} else if (isBlack(entry.value)) {
					countB++;
				}
			}

			if (countB == entries.size()) {
				continue;
			}
			if (countW == entries.size() - 1 &&
					countN == 1 &&
					number == entries.size()) {
				continue;
			}

			return false;
		}

		return true;
	}
	private boolean isContinuousInSearching() {
		int count = 0;
		Map<Integer, List<SummaryEntry>> summary = summaryBlack();

		// 黒のあるエリア数を数える
		for (List<SummaryEntry> entries : summary.values()) {
			for (SummaryEntry entry : entries) {
				if (isBlack(entry.value)) {
					count++;
					break;
				}
			}
		}

		return count == 0 || count == 1;
	}
	private boolean isValidCombinationInSearching() {
		Map<Integer, List<SummaryEntry>> summary = summary();

		for (List<SummaryEntry> entries : summary.values()) {
			int number = 0;
			int countE = 0;
			int countW = 0;
			int countN = 0;
			int countB = 0;

			// 各マスを数える・数字を検索する
			for (SummaryEntry entry : entries) {
				if (isWhite(entry.value)) {
					countW++;
				} else if (isNumber(entry.value)) {
					number = entry.value;
					countN++;
				} else if (isBlack(entry.value)) {
					countB++;
				} else {
					countE++;
				}
			}

			if (countE == entries.size() ||
					countW == entries.size() ||
					countB == entries.size()) {
				continue;
			}
			if (countW == entries.size() - 1 &&
					countN == 1 &&
					number >= entries.size()) {
				continue;
			}

			return false;
		}

		return true;
	}
	public boolean includesNotWhiteCells() {
		Map<Integer, List<SummaryEntry>> summary = summaryWhite();

		for (List<SummaryEntry> entries : summary.values()) {
			int count = 0;

			// 白マスを数える
			for (SummaryEntry entry : entries) {
				if (isWhite(entry.value)) {
					count++;
				}
			}

			if (count == entries.size()) {
				return false;
			}
		}

		return true;
	}
	public boolean isNumberOfCellsMoreThanNumber() {
		Map<Integer, List<SummaryEntry>> summary = summaryWhite();

		for (List<SummaryEntry> entries : summary.values()) {
			int number = 0;

			// 数字を検索する
			for (SummaryEntry entry : entries) {
				if (isNumber(entry.value)) {
					number = entry.value;
					break;
				}
			}

			if (number != 0 &&
					number > entries.size()) {
				return false;
			}
		}

		return true;
	}
	private boolean isNumberOfCellsLessThanMaxNumber() {
		int max_number = 0;
		Map<Integer, List<SummaryEntry>> summary = summary();

		for (List<SummaryEntry> entries : summary.values()) {
			int number = 0;

			// 数字を検索する
			for (SummaryEntry entry : entries) {
				if (isNumber(entry.value)) {
					number = entry.value;
					break;
				}
			}

			if (number > max_number) {
				max_number = number;
			}
		}

		for (List<SummaryEntry> entries : summary.values()) {
			int count = 0;

			for (SummaryEntry entry : entries) {
				if (isWhite(entry.value)) {
					count++;
				}
			}

			if (count >= max_number) {
				return false;
			}
		}

		return true;
	}
	public boolean validate() {
		return notContains2X2() &&
				isContinuous() &&
				isValidCombination();
	}
	public boolean validateInSearching() {
		return notContains2X2() &&
				isContinuousInSearching() &&
				isValidCombinationInSearching() &&
				includesNotWhiteCells() &&
				isNumberOfCellsMoreThanNumber() &&
				isNumberOfCellsLessThanMaxNumber();
	}

	/**
	 * Fill
	 */
	private void fillNeighborCells() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();

		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				if (i > 0 && j > 0) {
					if (isNumber(mBoard.get(i - 1, j)) &&
							isNumber(mBoard.get(i, j - 1))) {
						mBoard.put(i - 1, j - 1, B);
						mBoard.put(i, j, B);
						invalidate();
					} else if (isNumber(mBoard.get(i - 1, j - 1)) &&
							isNumber(mBoard.get(i, j))) {
						mBoard.put(i - 1, j, B);
						mBoard.put(i, j - 1, B);
						invalidate();
					}
				}
				if (i >= 2 &&
						isNumber(mBoard.get(i - 2, j)) &&
						isNumber(mBoard.get(i, j))) {
					mBoard.put(i - 1, j, B);
					invalidate();
				}
				if (j >= 2 &&
						isNumber(mBoard.get(i, j - 2)) &&
						isNumber(mBoard.get(i, j))) {
					mBoard.put(i, j - 1, B);
					invalidate();
				}
			}
		}
	}
	private void fillCellsInAreaWithoutNumber() {
		Map<Integer, List<SummaryEntry>> summary = summaryWhite();

		for (List<SummaryEntry> entries : summary.values()) {
			int number = 0;

			// 数字を検索する
			for (SummaryEntry entry : entries) {
				if (isNumber(entry.value)) {
					number = entry.value;
					break;
				}
			}

			if (number == 0) {
				for (SummaryEntry entry : entries) {
					final int i = entry.y;
					final int j = entry.x;

					mBoard.put(i, j, B);
					invalidate();
				}
			}
		}
	}
	private void fillInnerCellsInAreaWithNumber() {
		Map<Integer, List<SummaryEntry>> summary = summaryWhite();

		for (Map.Entry<Integer, List<SummaryEntry>> pair : summary.entrySet()) {
			int number = 0;
			int index = pair.getKey();
			List<SummaryEntry> entries = pair.getValue();

			// 数字を検索する
			for (SummaryEntry entry : entries) {
				if (isNumber(entry.value)) {
					number = entry.value;
					break;
				}
			}

			if (number != 0 && number == entries.size()) {
				for (SummaryEntry entry : summary.get(index)) {
					final int i = entry.y;
					final int j = entry.x;

					if (!isFilled(mBoard.get(i, j))) {
						mBoard.put(i, j, W);
						invalidate();
					}
				}
			}
		}
	}
	private void fillOuterCellsInAreaWithNumber() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();
		Map<Integer, List<SummaryEntry>> summary = summary();
		Matrix group = group();

		for (Map.Entry<Integer, List<SummaryEntry>> pair : summary.entrySet()) {
			int number = 0;
			int index = pair.getKey();
			List<SummaryEntry> entries = pair.getValue();

			// 数字を検索する
			for (SummaryEntry entry : entries) {
				if (isNumber(entry.value)) {
					number = entry.value;
					break;
				}
			}

			if (number != 0 && number == entries.size()) {
				for (SummaryEntry entry : entries) {
					final int i = entry.y;
					final int j = entry.x;

					if (i > 0 && group.get(i - 1, j) != index) {
						mBoard.put(i - 1, j, B);
						invalidate();
					}
					if (j > 0 && group.get(i, j - 1) != index) {
						mBoard.put(i, j - 1, B);
						invalidate();
					}
					if (i < h - 1 && group.get(i + 1, j) != index) {
						mBoard.put(i + 1, j, B);
						invalidate();
					}
					if (j < w - 1 && group.get(i, j + 1) != index) {
						mBoard.put(i, j + 1, B);
						invalidate();
					}
				}
			}
		}
	}
	private void fillCellsExtensible() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();
		Map<Integer, List<SummaryEntry>> summary = summaryWhite();

		for (Map.Entry<Integer, List<SummaryEntry>> pair : summary.entrySet()) {
			int number = 0;
			int count = 0;
			int index = pair.getKey();
			List<SummaryEntry> entries = pair.getValue();

			// 白マスを数える・数字を検索する
			for (SummaryEntry entry : entries) {
				if (isWhite(entry.value)) {
					count++;
				} else if (isNumber(entry.value)) {
					number = entry.value;
				}
			}

			if ((number != 0 && number > entries.size()) ||
					count == entries.size()) {
				List<Position> positions = new ArrayList<Position>();

				for (SummaryEntry entry : summary.get(index)) {
					final int i = entry.y;
					final int j = entry.x;

					if (i > 0 && !isFilled(mBoard.get(i - 1, j))) {
						positions.add(new Position(j, i - 1));
					}
					if (j > 0 && !isFilled(mBoard.get(i, j - 1))) {
						positions.add(new Position(j - 1, i));
					}
					if (i < h - 1 && !isFilled(mBoard.get(i + 1, j))) {
						positions.add(new Position(j, i + 1));
					}
					if (j < w - 1 && !isFilled(mBoard.get(i, j + 1))) {
						positions.add(new Position(j + 1, i));
					}
				}

				if (positions.size() == 1) {
					final int i = positions.get(0).y;
					final int j = positions.get(0).x;

					// ラベリングからやり直す必要がある
					mBoard.put(i, j, W);
					invalidate();
					return;
				}
			}
		}
	}
	public void fill() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();
		int count = 0;

		while (true) {
			int next_count = 0;

			for (int i=0;i<h;i++) {
				for (int j=0;j<w;j++) {
					if (!isFilled(mBoard.get(i, j))) {
						next_count++;
					}
				}
			}

			if (next_count == count) {
				return;
			}

			count = next_count;

			fillNeighborCells();
			fillCellsInAreaWithoutNumber();
			fillInnerCellsInAreaWithNumber();
			fillOuterCellsInAreaWithNumber();
			fillCellsExtensible();
		}
	}

	/**
	 * Solve
	 */
	private List<Position> findNotDecidedYet() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();
		List<Position> positions = new ArrayList<Position>();

		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				if (!isFilled(mBoard.get(i, j))) {
					positions.add(new Position(j, i));
				}
			}
		}

		return positions;
	}
	public boolean solve() {
		Stack<Matrix> stack = new Stack<Matrix>();
		stack.add(mBoard);

		while (!stack.isEmpty()) {
			mBoard = stack.pop();
			invalidate();

			if (validateInSearching()) {
				fill();

				List<Position> positions = findNotDecidedYet();

				if (!positions.isEmpty()) {
					final int i = positions.get(0).y;
					final int j = positions.get(0).x;
					System.out.println(String.format("DEBUG[%d, %d]:", i, j));
					System.out.println(toString());

					mBoard.put(i, j, B);
					stack.push(mBoard.clone());
					mBoard.put(i, j, W);
					stack.push(mBoard.clone());
				} else if (validate()) {
					System.out.println("FOUND:");
					System.out.println(toString());
					return true;
				} else {
					System.out.println("NONE:");
					System.out.println(toString());
				}
			}
		}

		return false;
	}

	/**
	 * Interface
	 */
	@Override
	public String toString() {
		final int w = mBoard.getW();
		final int h = mBoard.getH();

		StringBuilder sb = new StringBuilder();
		for (int i=0;i<h;i++) {
			for (int j=0;j<w;j++) {
				int value = mBoard.get(i, j);
				sb.append(Utils.valueToString(value));

				// 最終行は改行をスキップ
				if (j == w - 1 && i != h - 1) {
					sb.append("\n");
				}
			}
		}
		return sb.toString();
	}

	/**
	 * Main
	 */
	static public void main(String[] args) {
		try {
			Matrix matrix = Utils.readMatrix(System.in);
			Nurikabe nurikabe = new Nurikabe(matrix);
			System.out.println(nurikabe);
			System.out.println(nurikabe.solve());
			System.out.println(nurikabe.validate());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
