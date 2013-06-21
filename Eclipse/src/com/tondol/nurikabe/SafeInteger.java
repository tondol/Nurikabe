package com.tondol.nurikabe;

public class SafeInteger {
	private Integer mObject = null;

	public SafeInteger(Integer object) {
		mObject = object;
	}

	public int intValue(int defValue) {
		if (mObject != null) {
			return mObject.intValue();
		}

		return defValue;
	}
}
