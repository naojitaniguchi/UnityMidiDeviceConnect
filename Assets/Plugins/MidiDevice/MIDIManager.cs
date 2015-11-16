using UnityEngine;
using System.Collections;
using System;
using System.Collections.Generic;

/**
 * Copyright Miselu, Inc.  2015
 */

// This class makes sure there is a single MIDI object in the game system
public class MIDIManager : MonoBehaviour {
	
	public static MIDI MIDIObject { get; private set; }

	void Awake() {
		if (MIDIObject == null)
		{
			// Avoid duplication
			MIDIObject = GameObject.FindObjectOfType<MIDI>();
			
			if (MIDIObject == null) {
				MIDIObject = new GameObject(typeof(MIDI).ToString()).AddComponent<MIDI>();
			}
		}
	}
}
