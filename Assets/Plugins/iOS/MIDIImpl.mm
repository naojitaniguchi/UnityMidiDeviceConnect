//
//  MIDIImpl.mm
//  Unity-iPhone
//
//  Created by Christopher Cotton on 4/3/15.
//  Modified by Naoji Taniguchi on 2015/11/16
//
//

#import "MIDIImpl.h"
#import <CoreMIDI/CoreMIDI.h>

#define MIDI_STATUS               (0x80)

#define MIDI_CMD_MASK             (0xF0)

#define MIDI_NOTE_OFF             (0x80)
#define MIDI_NOTE_ON              (0x90)


@interface MIDIImpl ()
+(instancetype)shared;

@property (assign,nonatomic) MIDIClientRef client;
@property (assign,nonatomic) MIDIPortRef outputPort;
@property (assign,nonatomic) MIDIPortRef inputPort;

@property (assign,nonatomic) MIDIEndpointRef virtualSource;

@property (copy,nonatomic) NSString* name;

@property (strong,nonatomic) NSMutableArray* internalSources;
@property (strong,nonatomic) NSMutableArray* internalDestinations;

-(void)handleNotification:(const MIDINotification*)message;
-(void)handleMidi:(const MIDIPacketList*)packetList;
@end


void CoreMIDINotificationHandler (const MIDINotification *message, void *refCon) {
    MIDIImpl *manager = (__bridge MIDIImpl*) refCon;
    [manager handleNotification:message];
}

void CoreMIDIReadHandler (const MIDIPacketList *pktList, void *refCon, void *srcRefCon) {
    MIDIImpl *manager = (__bridge MIDIImpl*) refCon;
    [manager handleMidi:pktList];
}

extern "C"
{
    void MIDI_Init() {
        [MIDIImpl shared];
    }
    
}

@implementation MIDIImpl

+(instancetype)shared {
    static MIDIImpl *_shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [self new];
    });
    
    return _shared;
}


- (instancetype)init
{
    return [self initWithName:@"Visualizer"];
}

- (instancetype)initWithName:(NSString *)name {
    
    self = [super init];
    if (self) {
        _name = name;
        _internalSources = [NSMutableArray array];
        _internalDestinations = [NSMutableArray array];
        
        OSStatus ret = MIDIClientCreate((__bridge CFStringRef)self.name,CoreMIDINotificationHandler, (__bridge void *)(self), &_client);
        if (ret) {
            NSLog(@"Error setting up client");
        }
        
        ret = MIDIInputPortCreate(_client, (__bridge CFStringRef)self.name, CoreMIDIReadHandler, (__bridge void *)(self), &_inputPort);
        if (ret) {
            NSLog(@"Error setting up input port");
        }
        
        ret = MIDIDestinationCreate(_client, (__bridge CFStringRef)self.name, CoreMIDIReadHandler, (__bridge void *)(self), &_virtualSource);
        if (ret) {
            NSLog(@"Error setting up MIDIDestinationCreate");
        }
        
        //Get MIDI Endpoint and connect to midi port
        MIDIPortRef inputPortRef;
        OSStatus err;
        ItemCount sourceCount = MIDIGetNumberOfSources();
        for (ItemCount i = 0; i < sourceCount; i++) {
            MIDIEndpointRef sourcePointRef = MIDIGetSource(i);
            err = MIDIPortConnectSource(inputPortRef, sourcePointRef, NULL);
            if (err != noErr) {
                NSLog(@"MIDIPortConnectSource err = %d", err);
            }
        }
    }
    return self;
}

-(void)handleNotification:(const MIDINotification*)message {
    
}

-(void)handleMidi:(const MIDIPacketList*)packetList {
//    NSLog(@"handleMidi %@", @(packetList->numPackets));
    
    // Parse into a string
    
    //    NSLog(@"PacketList: %u", packetList->numPackets);
    const MIDIPacket *packet = &packetList->packet[0];
    NSMutableString* result = [NSMutableString stringWithCapacity:packet->length];
    
    for (int i = 0; i < packetList->numPackets; ++i) {
        NSUInteger offset = 0;
        for (offset = 0; offset < packet->length; offset++) {
            Byte status = packet->data[offset] & MIDI_CMD_MASK;
            if (status < MIDI_STATUS) {
                continue;
            }
            
            if (status == MIDI_NOTE_ON || status == MIDI_NOTE_OFF) {
                if (offset + 2 < packet->length) {
                    [result appendFormat:@"%02X%02X%02X", status, packet->data[offset + 1], packet->data[offset + 2]];
                    offset += 2;
                }
            }
        }
        
        // start off with parsing just Note On, Note Off
        packet = MIDIPacketNext(packet);
    }

    if (result.length > 0) {
//        NSLog(@"Sending Message %@", result);
        UnitySendMessage("MIDI", "OnMIDIData", strdup([result UTF8String]));
    }
}

@end
