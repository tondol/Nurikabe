package com.tondol.nurikabe;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Utils {
	static public int stringToValue(String s) {
		if (s.equals(" ")) {
			return Nurikabe.W;
		} else if (s.matches("\\d")) {
			return Integer.parseInt(s);
		} else if (s.equals("#")) {
			return Nurikabe.B;
		} else {
			return 0;
		}
	}
	static public String valueToString(int value) {
		if (value >= 0 && value <= 9) {
			return String.valueOf(value);
		} else if (value == Nurikabe.W) {
			return " ";
		} else if (value == Nurikabe.B) {
			return "#";
		} else {
			return "0";
		}
	}

	static public Matrix readNurikabe(InputStream in) throws IOException {
		BufferedReader br = new BufferedReader(new InputStreamReader(in));
		String line = br.readLine();

		Pattern pattern = Pattern.compile("(\\d+)\\s+(\\d+)");
		Matcher matcher = pattern.matcher(line);
		if (!matcher.find()) {
			return null;
		}

		int n = Integer.parseInt(matcher.group(1));
		int m = Integer.parseInt(matcher.group(2));
		Matrix matrix = new Matrix(m, n);

		for (int i=0;i<n;i++) {
			String row = br.readLine();
			for (int j=0;j<m;j++) {
				String s = row.substring(j, j + 1);
				matrix.put(i, j, stringToValue(s));
			}
		}

		return matrix;
	}
}
