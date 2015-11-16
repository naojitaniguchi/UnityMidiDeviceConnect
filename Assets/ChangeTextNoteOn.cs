using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class ChangeTextNoteOn : MonoBehaviour {

	// Use this for initialization
	void Start () {
		MIDI.noteEvent += OnNoteEvent;
	}

	void OnDestroy() {
		MIDI.noteEvent -= OnNoteEvent;
	}

	
	// Update is called once per frame
	void Update () {
	
	}

	void OnNoteEvent(bool noteDown, int note) {
		if (noteDown) {
			gameObject.GetComponent<Text>().text = "noteDown:" + note.ToString();
			//float part = 1.0f / prototypes.Length;
			//int adjusted = note % prototypes.Length;

			Debug.Log( note );
		} else {
			// nothing right now
		}
	}

}
