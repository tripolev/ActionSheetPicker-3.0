//
//Copyright (c) 2011, Tim Cinel
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//* Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//* Redistributions in binary form must reproduce the above copyright
//notice, this list of conditions and the following disclaimer in the
//documentation and/or other materials provided with the distribution.
//* Neither the name of the <organization> nor the
//names of its contributors may be used to endorse or promote products
//derived from this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//åLOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ActionSheetIconStringPicker.h"

@interface ActionSheetIconStringPicker()
@property (nonatomic,strong) NSArray *data;
@property (nonatomic,strong) NSArray *icons;
@property (nonatomic,assign) NSInteger selectedIndex;
@end

@implementation ActionSheetIconStringPicker

typedef enum {
    IconRowPart = 1,
    LabelRowPart
} rowParts;

+(instancetype)showPickerWithTitle:(NSString *)title icons:(NSArray *)images rows:(NSArray *)strings initialSelection:(NSInteger)index doneBlock:(ActionIconStringDoneBlock)doneBlock cancelBlock:(ActionIconStringCancelBlock)cancelBlockOrNil origin:(id)origin {
    ActionSheetIconStringPicker * picker = [[ActionSheetIconStringPicker alloc] initWithTitle:title icons:images rows:strings initialSelection:index doneBlock:doneBlock cancelBlock:cancelBlockOrNil origin:origin];
    [picker showActionSheetPicker];
    return picker;
}

-(instancetype)initWithTitle:(NSString *)title icons:(NSArray *)images rows:(NSArray *)strings initialSelection:(NSInteger)index doneBlock:(ActionIconStringDoneBlock)doneBlock cancelBlock:(ActionIconStringCancelBlock)cancelBlockOrNil origin:(id)origin {
    self = [self initWithTitle:title icons:images rows:strings initialSelection:index target:nil successAction:nil cancelAction:nil origin:origin];
    if (self) {
        self.onActionSheetDone = doneBlock;
        self.onActionSheetCancel = cancelBlockOrNil;
    }
    return self;
}

+(instancetype)showPickerWithTitle:(NSString *)title icons:(NSArray *)images rows:(NSArray *)data initialSelection:(NSInteger)index target:(id)target successAction:(SEL)successAction cancelAction:(SEL)cancelActionOrNil origin:(id)origin {
    ActionSheetIconStringPicker *picker = [[ActionSheetIconStringPicker alloc] initWithTitle:title icons:images rows:data initialSelection:index target:target successAction:successAction cancelAction:cancelActionOrNil origin:origin];
    [picker showActionSheetPicker];
    return picker;
}

-(instancetype)initWithTitle:(NSString *)title icons:(NSArray *)images rows:(NSArray *)data initialSelection:(NSInteger)index target:(id)target successAction:(SEL)successAction cancelAction:(SEL)cancelActionOrNil origin:(id)origin {
    self = [self initWithTarget:target successAction:successAction cancelAction:cancelActionOrNil origin:origin];
    if (self) {
        self.icons = images;
        self.data = data;
        self.selectedIndex = index;
        self.title = title;
    }
    return self;
}

-(UIView *)configuredPickerView {
    if (!self.data)
        return nil;
    CGRect pickerFrame = CGRectMake(0, 40, self.viewSize.width, 216);
    UIPickerView *stringPicker = [[UIPickerView alloc] initWithFrame:pickerFrame];
    stringPicker.delegate = self;
    stringPicker.dataSource = self;
    [stringPicker selectRow:self.selectedIndex inComponent:0 animated:NO];
    if (self.data.count == 0) {
        stringPicker.showsSelectionIndicator = NO;
        stringPicker.userInteractionEnabled = NO;
    } else {
        stringPicker.showsSelectionIndicator = YES;
        stringPicker.userInteractionEnabled = YES;
    }
    
    //need to keep a reference to the picker so we can clear the DataSource / Delegate when dismissing
    self.pickerView = stringPicker;
    
    return stringPicker;
}

-(void)notifyTarget:(id)target didSucceedWithAction:(SEL)successAction origin:(id)origin {
    if (self.onActionSheetDone) {
        id selectedObject = (self.data.count > 0) ? (self.data)[(NSUInteger) self.selectedIndex] : nil;
        _onActionSheetDone(self, self.selectedIndex, selectedObject);
        return;
    }
    else if (target && [target respondsToSelector:successAction]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:successAction withObject:@(self.selectedIndex) withObject:origin];
#pragma clang diagnostic pop
        return;
    }
    NSLog(@"Invalid target/action ( %s / %s ) combination used for ActionSheetPicker and done block is nil.", object_getClassName(target), sel_getName(successAction));
}

-(void)notifyTarget:(id)target didCancelWithAction:(SEL)cancelAction origin:(id)origin {
    if (self.onActionSheetCancel) {
        _onActionSheetCancel(self);
        return;
    }
    else if (target && cancelAction && [target respondsToSelector:cancelAction]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:cancelAction withObject:origin];
#pragma clang diagnostic pop
    }
}

#pragma mark - UIPickerViewDelegate / DataSource
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedIndex = row;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.data.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    id obj = (self.data)[(NSUInteger) row];
    
    // return the object if it is already a NSString,
    // otherwise, return the description, just like the toString() method in Java
    // else, return nil to prevent exception
    
    if ([obj isKindOfClass:[NSString class]])
        return obj;
    
    if ([obj respondsToSelector:@selector(description)])
        return [obj performSelector:@selector(description)];
    
    return nil;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.frame.size.width - 30;
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 50;
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UIView* rowView;
    if (view) {
        rowView = view;
    } else {
        rowView = [[UIView alloc] init];
//        UIImage *icon = self.icons[row] dataManager.images[call.conclusion.file.fileID];
//        UIImage *icon = [[UIImage alloc] init];
        UIImageView *imageView =[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [imageView setTag:IconRowPart];
        [rowView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, pickerView.frame.size.width - 30 - 50, 50)];
//        [label setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:0];
        [label setTag:LabelRowPart];
        [label setFont:[UIFont systemFontOfSize:22]];
        [rowView addSubview:label];
    }
    
    UIImageView *rowImageView = (UIImageView *) [rowView viewWithTag: IconRowPart];
    [rowImageView setImage:self.icons[row]];
    
    UILabel *rowLabel = (UILabel *) [rowView viewWithTag:LabelRowPart];
//    NSLog(@"row: %d self.data[row]: %@", row, self.data[row]);
    [rowLabel setText:[self pickerView:pickerView titleForRow:row forComponent:component]];
//    [rowLabel sizeToFit];
    
//    [rowView sizeToFit];
    
    return rowView;
    
}

@end
