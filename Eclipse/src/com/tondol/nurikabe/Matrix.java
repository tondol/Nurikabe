package com.tondol.nurikabe;

public class Matrix implements Cloneable {
	private int mW = 0;
	private int mH = 0;
	private int[] mValues = null;

	public Matrix(int w, int h) {
		this(w, h, new int[w * h]);
	}
	public Matrix(int w, int h, int[] values) {
		mW = w;
		mH = h;
		mValues = values;
	}

	public int getW() {
		return mW;
	}
	public int getH() {
		return mH;
	}

	public int get(int i, int j) {
		return mValues[i * mW + j];
	}
	public void put(int i, int j, int value) {
		mValues[i * mW + j] = value;
	}

	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		for (int i=0;i<mH;i++) {
			for (int j=0;j<mW;j++) {
				sb.append(mValues[i * mW + j]);

				// カンマ区切りで出力する
				// 最終行は改行をスキップ
				if (j == mW - 1) {
					if (i != mH - 1) {
						sb.append("\n");
					}
				} else {
					sb.append(", ");
				}
			}
		}
		return sb.toString();
	}
	@Override
	protected Matrix clone() {
		return new Matrix(mW, mH, mValues.clone());
	}
}
