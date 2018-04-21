//
//  Message.swift
//  FireChat-Swift
//
//  Created by Katherine Fang on 8/20/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

#import "ChatMessage.h"
#import "ChatMessageMetadata.h"

@implementation ChatMessage

-(id)init {
    self = [super init];
    if (self) {
        // initialization
        self.metadata = [[ChatMessageMetadata alloc] init];
    }
    return self;
}

// ConversationId custom getter
- (NSString *) conversationId {
    if (!_conversationId) {
        return _recipient;
    }
    else {
        return _conversationId;
    }
}

//@synthesize imageURL = _imageURL;

// imageURL custom getter
- (NSString *) imageURL {
    return self.metadata.url;
}

-(void)setImageURL:(NSString *)url
{
    self.metadata.url = url;
}

//- (NSDictionary *) asDictionary {
//    NSDictionary *dict = [[NSMutableDictionary alloc] init];
//    dict[]
//}

-(NSDictionary *)snapshot {
    if (!_snapshot) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
//        @property (nonatomic, strong) NSString *messageId; // firebase-key
//        @property (nonatomic, strong) NSString *text; // firebase
//        @property (nonatomic, strong) NSString *sender; // firebase
//        @property (nonatomic, strong) NSString *senderFullname; // firebase
//        @property (nonatomic, strong) NSString *recipient; // firebase
//        @property (nonatomic, strong) NSString *recipientFullName; // firebase
//        @property (nonatomic, strong) NSString *channel_type; // firebase
//        @property (nonatomic, strong) NSString *lang; // firebase
//        @property (nonatomic, strong) NSDate *date; // firebase (converted to timestamp)
        
//        @property (nonatomic, assign) int status; // firebase
//        @property (nonatomic, strong) NSString *mtype; // firebase
//        @property (nonatomic, strong) NSString *subtype; // firebase
//        @property (strong, nonatomic) NSString *imageURL; // firebase
//        @property (strong, nonatomic) NSString *imageFilename; // firebase - used to save image locally
//        @property (nonatomic, strong) ChatMessageMetadata *metadata; // firebase
//        @property (nonatomic, strong) NSDictionary *attributes; // firebase
        data[MSG_FIELD_SENDER] = self.sender;
        data[MSG_FIELD_SENDER_FULLNAME] = self.senderFullname;
        data[MSG_FIELD_RECIPIENT] = self.recipient;
        data[MSG_FIELD_RECIPIENT_FULLNAME] = self.recipientFullName;
        data[MSG_FIELD_CHANNEL_TYPE] = self.channel_type;
        data[MSG_FIELD_LANG] = self.lang;
        NSLog(@"time original: %@", self.date);
        long long milliseconds = (long long)([self.date timeIntervalSince1970] * 1000.0);
        NSLog(@"time converted millis: %lld", milliseconds);
        data[MSG_FIELD_TIMESTAMP] = @(milliseconds);
        data[MSG_FIELD_STATUS] = @(self.status);
        data[MSG_FIELD_TYPE] = self.mtype;
        data[MSG_FIELD_SUBTYPE] = self.subtype;
//        data[MSG_FIELD_IMAGE_URL] = self.imageURL;
        data[MSG_FIELD_IMAGE_FILENAME] = self.imageFilename;
        data[MSG_FIELD_METADATA] = self.metadata.asDictionary;
        data[MSG_FIELD_ATTRIBUTES] = self.attributes;
        _snapshot = data;
    }
    return _snapshot;
}

-(NSString *)snapshotAsJSONString {
    NSString * json = nil;
    if (self.snapshot && [self.snapshot isKindOfClass:[NSDictionary class]]) {
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:self.snapshot options:0 error:&err];
        if (err) {
            NSLog(@"Error: %@", err);
        }
        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return json;
}

//-(NSString *)attributesAsJSONString {
//    NSString * json = nil;
////    NSLog(@"valid json? %d", [NSJSONSerialization isValidJSONObject:self.attributes]);
//    if (self.attributes && [self.attributes isKindOfClass:[NSDictionary class]]) {
//        NSError * err;
//        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:self.attributes options:0 error:&err];
//        if (err) {
//            NSLog(@"Error: %@", err);
//        }
//        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    }
//    return json;
//}

-(NSString *)dateFormattedForListView {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    NSString *date = [timeFormat stringFromDate:self.date];
    return date;
}

-(void)updateStatusOnFirebase:(int)status {
    NSDictionary *message_dict = @{
                                   @"status": [NSNumber numberWithInt:status]
                                   };
    [self.ref updateChildValues:message_dict];
}

+(ChatMessage *)messageFromSnapshotFactory:(FIRDataSnapshot *)snapshot {
    NSString *conversationId = snapshot.value[MSG_FIELD_CONVERSATION_ID];
    NSString *type = snapshot.value[MSG_FIELD_TYPE];
    NSString *subtype = snapshot.value[MSG_FIELD_SUBTYPE];
    NSString *channel_type = snapshot.value[MSG_FIELD_CHANNEL_TYPE];
    if (!channel_type) {
        channel_type = MSG_CHANNEL_TYPE_DIRECT;
    }
    NSString *text = snapshot.value[MSG_FIELD_TEXT];
    NSString *sender = snapshot.value[MSG_FIELD_SENDER];
    NSString *senderFullname = snapshot.value[MSG_FIELD_SENDER_FULLNAME];
    NSString *recipient = snapshot.value[MSG_FIELD_RECIPIENT];
    NSString *recipientFullname = snapshot.value[MSG_FIELD_RECIPIENT_FULLNAME];
    NSString *lang = snapshot.value[MSG_FIELD_LANG];
    NSNumber *timestamp = snapshot.value[MSG_FIELD_TIMESTAMP];
    NSDictionary *attributes = (NSDictionary *) snapshot.value[MSG_FIELD_ATTRIBUTES];
    
    ChatMessage *message = [[ChatMessage alloc] init];
    
    message.snapshot = (NSDictionary *) snapshot.value;
    message.attributes = attributes;
    message.metadata = [ChatMessageMetadata fromSnapshotFactory:snapshot];
    message.ref = snapshot.ref;
    message.messageId = snapshot.key;
    message.conversationId = conversationId;
    message.mtype = type;
//    [message setCorrectText:message text:text];
    message.text = text;
    
    message.lang = lang;
    message.subtype = subtype;
    if ([message.mtype isEqualToString:MSG_TYPE_IMAGE]) {
        message.media = YES;
    }
    message.channel_type = channel_type;
    message.sender = sender;
    message.senderFullname = senderFullname;
    message.date = [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue/1000];
    int status = [(NSNumber *)snapshot.value[MSG_FIELD_STATUS] intValue];
    if (status < 100) {
        status = 100;
    }
    message.status = status;
    message.recipient = recipient;
    message.recipientFullName = recipientFullname;
    return message;
}

-(void)setCorrectText:(ChatMessage *)message text:(NSString *)text {
    // text validation
    if (!text) { // never nil
        message.text = @"";
    }
    if (text) { // always space-trimmed
        message.text = [message.text stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    // always show a placeholder url for an image
    if (message.typeImage && message.text.length == 0) {
        message.text = [ChatMessage imageTextPlaceholder:message.metadata.url];
    }
}

-(NSMutableDictionary *)asFirebaseMessage {
    // firebase message dictionary
    NSMutableDictionary *message_dict = [[NSMutableDictionary alloc] init];
    // always
    [message_dict setObject:self.text forKey:MSG_FIELD_TEXT];
    [message_dict setObject:self.channel_type forKey:MSG_FIELD_CHANNEL_TYPE];
    if (self.senderFullname) {
        [message_dict setObject:self.senderFullname forKey:MSG_FIELD_SENDER_FULLNAME];
    }
    
    if (self.subtype) {
        [message_dict setObject:self.subtype forKey:MSG_FIELD_SUBTYPE];
    }
    
    if (self.recipientFullName) {
        [message_dict setObject:self.recipientFullName forKey:MSG_FIELD_RECIPIENT_FULLNAME];
    }
    
    if (self.mtype) {
        [message_dict setObject:self.mtype forKey:MSG_FIELD_TYPE];
    }
    
    if (self.attributes) {
        [message_dict setObject:self.attributes forKey:MSG_FIELD_ATTRIBUTES];
    }
    
//    if (self.imageURL) {
//        [message_dict setObject:self.imageURL forKey:MSG_FIELD_IMAGE_URL];
//    }
    
    if (self.metadata) {
        [message_dict setObject:self.metadata.asDictionary forKey:MSG_FIELD_METADATA];
//        [message_dict setObject:@(self.metadata.width) forKey:MSG_FIELD_IMAGE_WIDTH];
//        [message_dict setObject:@(self.metadata.height) forKey:MSG_FIELD_IMAGE_HEIGHT];
    }
    
    if (self.lang) {
        [message_dict setObject:self.lang forKey:MSG_FIELD_LANG];
    }
    return message_dict;
}

-(BOOL)isDirect {
    return [self.channel_type isEqualToString:MSG_CHANNEL_TYPE_DIRECT] ? YES : NO;
}

-(BOOL)typeText {
    return [self.mtype isEqualToString:MSG_TYPE_TEXT] ? YES : NO;
}

-(BOOL)typeImage {
    return [self.mtype isEqualToString:MSG_TYPE_IMAGE] ? YES : NO;
}

+(NSString *)imageTextPlaceholder:(NSString *)imageURL {
    return [[NSString alloc] initWithFormat:@"Image: %@", imageURL];
}

@end

