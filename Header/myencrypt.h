//
//  myencrypt.h
//  MEWDecrypt
//
//  Created by Zheng on 20/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//



#ifndef myencrypt_h
#define myencrypt_h

#include "myencrypt_0.h"

__attribute((obfuscate))
static inline NSString *D(NSString *d) {
    const char *input = [d UTF8String];
    size_t inlen = strlen(input);
    size_t dstlen = inlen * 2;
    unsigned char *dstbuf = (unsigned char *)malloc(dstlen);
    bzero(dstbuf, dstlen);
    size_t outlen = dstlen;
    if (0 == _B(dstbuf, dstlen, &outlen, (unsigned char *)input, inlen)) {
        unsigned char iv[8] = {0x01, 0xfe, 0x29, 0xc7, 0x18, 0x44, 0x46, 0x94};
        unsigned char *todec = dstbuf;
        size_t declen = outlen;
        size_t enclen = declen;
        unsigned char *padenc = (unsigned char *)malloc(enclen);
        bzero(padenc, enclen);
        static const char *enckey = "NjJjM2NkNzA3YjU1MjJkYmRlYmRkNDg5M2E2YzU2MjZiZjE1NWVmMg==";
        size_t keylen = strlen(enckey);
        size_t keykeylen = keylen * 2;
        size_t keyoutlen = keykeylen;
        unsigned char *keybuf = (unsigned char *)malloc(keykeylen);
        bzero(keybuf, keykeylen);
        if (0 == _B(keybuf, keykeylen, &keyoutlen, (unsigned char *)enckey, keylen)) {
            _X ctx;
            _I(&ctx);
            if (keybuf) {
                if (0 == _K(&ctx, keybuf, 320)) {
                    if (0 == _N(&ctx, DARWINDEV_MEEEEEEW_DECRYPT, declen, iv, todec, padenc)) {
                        
                    }
                }
            }
            _F(&ctx);
        }
        char *srcbuf = (char *)malloc(enclen);
        bzero(srcbuf, enclen);
        memcpy(srcbuf, padenc, enclen);
        size_t srclen = strlen(srcbuf);
        NSString *outs = [[NSString alloc] initWithBytes:srcbuf length:srclen encoding:NSUTF8StringEncoding];
        free(srcbuf);
        free(keybuf);
        free(padenc);
        return outs;
    }
    free(dstbuf);
    return nil;
}

/*
__attribute((obfuscate))
static inline NSString *E(NSString *e) {
    unsigned char iv[8] = {0x01, 0xfe, 0x29, 0xc7, 0x18, 0x44, 0x46, 0x94};
    const char *toenc = [e UTF8String];
    size_t enclen = strlen(toenc);
    size_t padlen = sizeof(char) * ((int)(enclen / 8) + 1) * 8;
    unsigned char *padenc = (unsigned char *)malloc(padlen);
    bzero(padenc, padlen);
    memcpy(padenc, toenc, enclen);
    size_t declen = padlen;
    unsigned char *paddec = (unsigned char *)malloc(declen);
    bzero(paddec, declen);
    size_t dstlen = padlen * 2;
    unsigned char *dstbuf = (unsigned char *)malloc(dstlen);
    bzero(dstbuf, dstlen);
    size_t outlen = dstlen;
    static const char *enckey = "NjJjM2NkNzA3YjU1MjJkYmRlYmRkNDg5M2E2YzU2MjZiZjE1NWVmMg==";
    size_t keylen = strlen(enckey);
    size_t keykeylen = keylen * 2;
    size_t keyoutlen = keykeylen;
    unsigned char *keybuf = (unsigned char *)malloc(keykeylen);
    bzero(keybuf, keykeylen);
    if (0 == _B(keybuf, keykeylen, &keyoutlen, (unsigned char *)enckey, keylen)) {
        _X ctx;
        _I(&ctx);
        if (keybuf) {
            if (0 == _K(&ctx, keybuf, 320)) {
                if (0 == _N(&ctx, DARWINDEV_MEEEEEEW_ENCRYPT, padlen, iv, padenc, paddec)) {
                    _A(dstbuf, dstlen, &outlen, paddec, declen);
                }
            }
        }
        _F(&ctx);
    }
    NSString *outs = [[NSString alloc] initWithBytes:dstbuf length:outlen encoding:NSUTF8StringEncoding];
    free(keybuf);
    free(padenc);
    free(paddec);
    free(dstbuf);
    return outs;
}
 */

#endif /* myencrypt_h */

