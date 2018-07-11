//
//  ConvertUtil.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/6/7.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "ConvertUtil.h"
#import "lame.h"

@implementation ConvertUtil
+(void)cafFile:(NSString *)cafFilePath toMp3File:(NSString* )mp3FilePath{
    @try {
        
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");
        fseek(pcm, 4*1024, SEEK_CUR);//去除多余的头部，不然会有咔嚓的一声噪音
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame, 2);//设置1为单通道，默认为2双通道
        lame_set_in_samplerate(lame, 8000.0);//11025.0
//        lame_set_VBR(lame, vbr_default);
        lame_set_brate(lame, 16);
        lame_set_mode(lame, 3);
        lame_set_quality(lame, 2); /* 2=high 5 = medium 7=low 音质*/
        lame_init_params(lame);
        
        do{
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0) {
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            }else{
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            }
            
            fwrite(mp3_buffer, write, 1, mp3);
            
            
        }while (read!=0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        NSLog(@"convert to mp3 succ %@",mp3FilePath);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }  
}
@end
