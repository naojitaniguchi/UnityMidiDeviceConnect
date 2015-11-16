using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

/**
 * Copyright Miselu, Inc.  2015
 */

public class MIDI : MonoBehaviour {

	public static event Action<bool, int> noteEvent;

	private void Awake() {
		Debug.Log("MIDI Awake");
		// Set the GameObject name to the class name for easy access from native plugin
		gameObject.name = GetType().ToString();
		DontDestroyOnLoad(this);
#if !UNITY_EDITOR
		MIDI_Init();
#endif
	}

	// Use this for initialization
	void Start () {
		// FIXME: need to make it turn it self off after a certain period of time
		Screen.sleepTimeout = SleepTimeout.NeverSleep;
	}
	
	// Update is called once per frame
	void Update () {
#if UNITY_EDITOR
		if (noteEvent == null) {
			return;
		}

		KeyCode[] keycodes = {KeyCode.Q, KeyCode.Alpha2, KeyCode.W, KeyCode.Alpha3, KeyCode.E, KeyCode.Alpha4, KeyCode.R, KeyCode.Alpha5, 
			KeyCode.T, KeyCode.Alpha6, KeyCode.Y, KeyCode.Alpha7, KeyCode.U, KeyCode.Alpha8, KeyCode.I, KeyCode.Alpha9, KeyCode.O,
			KeyCode.Alpha0, KeyCode.P};
		for(int i = 0; i < keycodes.Length; i++) {
			KeyCode keycode = keycodes[i];
			if (Input.GetKeyDown (keycode)) {
				string result = "90" + i.ToString("X2") + "7F";
				OnMIDIData(result);
			}
			if (Input.GetKeyUp(keycode)) {
				string result = "90" + i.ToString("X2") + "00";
				OnMIDIData(result);
			}
		}
#endif
	}

	private void OnMIDIData(string data) {
//		Debug.Log("Data receive " + data);
		if (noteEvent == null) {
			return;
		}

		int offset = 0;
		while (offset + 6 <= data.Length) {
			UInt16 status = Convert.ToUInt16(data.Substring(offset, 2), 16);
			UInt16 note = Convert.ToUInt16(data.Substring(offset + 2, 2), 16);
			UInt16 velocity = Convert.ToUInt16(data.Substring(offset + 4, 2), 16);
//			Debug.Log("Parsed " + status + " " + note + " " + velocity);
			if (status == 0x80 || status == 0x90) {
				bool noteOn = (status == 0x90 && velocity > 0);
				noteEvent(noteOn, note);
			}

			offset += 3;
		}
	}


#if UNITY_IOS
	[DllImport("__Internal")]
	private static extern void MIDI_Init();

#endif
}
