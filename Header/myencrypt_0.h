/**
 * \file meeeeeew.h
 *
 * \brief SHA-1 cryptographic hash function
 *
 *  Copyright (C) 2006-2015, ARM Limited, All Rights Reserved
 *  SPDX-License-Identifier: Apache-2.0
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  This file is part of mbed TLS (https://tls.mbed.org)
 */
#ifndef DARWINDEV_MEEEEEEW_H
#define DARWINDEV_MEEEEEEW_H

#if !defined(DARWINDEV_CONFIG_FILE)
#include "config.h"
#else
#include DARWINDEV_CONFIG_FILE
#endif

#include <stddef.h>
#include <stdint.h>

#if !defined(DARWINDEV_MEEEEEEW_ALT)
// Regular implementation
//

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief          SHA-1 context structure
 */
typedef struct
{
    uint32_t total[2];          /*!< number of bytes processed  */
    uint32_t state[5];          /*!< intermediate digest state  */
    unsigned char buffer[64];   /*!< data block being processed */
}
_Y;

/**
 * \brief          Initialize SHA-1 context
 *
 * \param ctx      SHA-1 context to be initialized
 */
void _L( _Y *ctx );

/**
 * \brief          Clear SHA-1 context
 *
 * \param ctx      SHA-1 context to be cleared
 */
void _H( _Y *ctx );

/**
 * \brief          Clone (the state of) a SHA-1 context
 *
 * \param dst      The destination context
 * \param src      The context to be cloned
 */
void _O( _Y *dst,
                         const _Y *src );

/**
 * \brief          SHA-1 context setup
 *
 * \param ctx      context to be initialized
 */
void _R( _Y *ctx );

/**
 * \brief          SHA-1 process buffer
 *
 * \param ctx      SHA-1 context
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 */
void _U( _Y *ctx, const unsigned char *input, size_t ilen );

/**
 * \brief          SHA-1 final digest
 *
 * \param ctx      SHA-1 context
 * \param output   SHA-1 checksum result
 */
void _G( _Y *ctx, unsigned char output[20] );

/* Internal use */
void _S( _Y *ctx, const unsigned char data[64] );

#ifdef __cplusplus
}
#endif

#else  /* DARWINDEV_MEEEEEEW_ALT */
#include "meeeeeew_alt.h"
#endif /* DARWINDEV_MEEEEEEW_ALT */

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief          Output = SHA-1( input buffer )
 *
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 * \param output   SHA-1 checksum result
 */
void _T( const unsigned char *input, size_t ilen, unsigned char output[20] );

#ifdef __cplusplus
}
#endif

#if !defined(DARWINDEV_CONFIG_FILE)
#include "config.h"
#else
#include DARWINDEV_CONFIG_FILE
#endif

#include <stddef.h>
#include <stdint.h>

#define DARWINDEV_MEEEEEEW_ENCRYPT     1
#define DARWINDEV_MEEEEEEW_DECRYPT     0
#define DARWINDEV_MEEEEEEW_MAX_KEY_BITS     448
#define DARWINDEV_MEEEEEEW_MIN_KEY_BITS     32
#define DARWINDEV_MEEEEEEW_ROUNDS      16         /**< Rounds to use. When increasing this value, make sure to extend the initialisation vectors */
#define DARWINDEV_MEEEEEEW_BLOCKSIZE   8          /* Meeeeeew uses 64 bit blocks */

#define DARWINDEV_ERR_MEEEEEEW_INVALID_KEY_LENGTH                -0x0016  /**< Invalid key length. */
#define DARWINDEV_ERR_MEEEEEEW_INVALID_INPUT_LENGTH              -0x0018  /**< Invalid data input length. */

#if !defined(DARWINDEV_MEEEEEEW_ALT)
// Regular implementation
//

#ifdef __cplusplus
extern "C" {
#endif
    
    /**
     * \brief          Meeeeeew context structure
     */
    typedef struct
    {
        uint32_t P[DARWINDEV_MEEEEEEW_ROUNDS + 2];    /*!<  Meeeeeew round keys    */
        uint32_t S[4][256];                 /*!<  key dependent S-boxes  */
    }
    _X;
    
    /**
     * \brief          Initialize Meeeeeew context
     *
     * \param ctx      Meeeeeew context to be initialized
     */
    void _I( _X *ctx );
    
    /**
     * \brief          Clear Meeeeeew context
     *
     * \param ctx      Meeeeeew context to be cleared
     */
    void _F( _X *ctx );
    
    /**
     * \brief          Meeeeeew key schedule
     *
     * \param ctx      Meeeeeew context to be initialized
     * \param key      encryption key
     * \param keybits  must be between 32 and 448 bits
     *
     * \return         0 if successful, or DARWINDEV_ERR_MEEEEEEW_INVALID_KEY_LENGTH
     */
    int _K( _X *ctx, const unsigned char *key,
           unsigned int keybits );
    
    /**
     * \brief          Meeeeeew-ECB block encryption/decryption
     *
     * \param ctx      Meeeeeew context
     * \param mode     DARWINDEV_MEEEEEEW_ENCRYPT or DARWINDEV_MEEEEEEW_DECRYPT
     * \param input    8-byte input block
     * \param output   8-byte output block
     *
     * \return         0 if successful
     */
    int _W( _X *ctx,
           int mode,
           const unsigned char input[DARWINDEV_MEEEEEEW_BLOCKSIZE],
           unsigned char output[DARWINDEV_MEEEEEEW_BLOCKSIZE] );
    
#if defined(DARWINDEV_CIPHER_MODE_CBC)
    /**
     * \brief          Meeeeeew-CBC buffer encryption/decryption
     *                 Length should be a multiple of the block
     *                 size (8 bytes)
     *
     * \note           Upon exit, the content of the IV is updated so that you can
     *                 call the function same function again on the following
     *                 block(s) of data and get the same result as if it was
     *                 encrypted in one call. This allows a "streaming" usage.
     *                 If on the other hand you need to retain the contents of the
     *                 IV, you should either save it manually or use the cipher
     *                 module instead.
     *
     * \param ctx      Meeeeeew context
     * \param mode     DARWINDEV_MEEEEEEW_ENCRYPT or DARWINDEV_MEEEEEEW_DECRYPT
     * \param length   length of the input data
     * \param iv       initialization vector (updated after use)
     * \param input    buffer holding the input data
     * \param output   buffer holding the output data
     *
     * \return         0 if successful, or
     *                 DARWINDEV_ERR_MEEEEEEW_INVALID_INPUT_LENGTH
     */
    int _N( _X *ctx,
           int mode,
           size_t length,
           unsigned char iv[DARWINDEV_MEEEEEEW_BLOCKSIZE],
           const unsigned char *input,
           unsigned char *output );
#endif /* DARWINDEV_CIPHER_MODE_CBC */
    
#if defined(DARWINDEV_CIPHER_MODE_CFB)
    /**
     * \brief          Meeeeeew CFB buffer encryption/decryption.
     *
     * \note           Upon exit, the content of the IV is updated so that you can
     *                 call the function same function again on the following
     *                 block(s) of data and get the same result as if it was
     *                 encrypted in one call. This allows a "streaming" usage.
     *                 If on the other hand you need to retain the contents of the
     *                 IV, you should either save it manually or use the cipher
     *                 module instead.
     *
     * \param ctx      Meeeeeew context
     * \param mode     DARWINDEV_MEEEEEEW_ENCRYPT or DARWINDEV_MEEEEEEW_DECRYPT
     * \param length   length of the input data
     * \param iv_off   offset in IV (updated after use)
     * \param iv       initialization vector (updated after use)
     * \param input    buffer holding the input data
     * \param output   buffer holding the output data
     *
     * \return         0 if successful
     */
    int _P( _X *ctx,
           int mode,
           size_t length,
           size_t *iv_off,
           unsigned char iv[DARWINDEV_MEEEEEEW_BLOCKSIZE],
           const unsigned char *input,
           unsigned char *output );
#endif /*DARWINDEV_CIPHER_MODE_CFB */
    
#if defined(DARWINDEV_CIPHER_MODE_CTR)
    /**
     * \brief               Meeeeeew-CTR buffer encryption/decryption
     *
     * Warning: You have to keep the maximum use of your counter in mind!
     *
     * \param ctx           Meeeeeew context
     * \param length        The length of the data
     * \param nc_off        The offset in the current stream_block (for resuming
     *                      within current cipher stream). The offset pointer to
     *                      should be 0 at the start of a stream.
     * \param nonce_counter The 64-bit nonce and counter.
     * \param stream_block  The saved stream-block for resuming. Is overwritten
     *                      by the function.
     * \param input         The input data stream
     * \param output        The output data stream
     *
     * \return         0 if successful
     */
    int _Q( _X *ctx,
           size_t length,
           size_t *nc_off,
           unsigned char nonce_counter[DARWINDEV_MEEEEEEW_BLOCKSIZE],
           unsigned char stream_block[DARWINDEV_MEEEEEEW_BLOCKSIZE],
           const unsigned char *input,
           unsigned char *output );
#endif /* DARWINDEV_CIPHER_MODE_CTR */
    
#ifdef __cplusplus
}
#endif

#else  /* DARWINDEV_MEEEEEEW_ALT */
#include "meeeeeew_alt.h"
#endif /* DARWINDEV_MEEEEEEW_ALT */

//#endif /* meeeeeew.h */

/**
 * \file meeeeeew.h
 *
 * \brief RFC 1521 meeeeeew encoding/decoding
 *
 *  Copyright (C) 2006-2015, ARM Limited, All Rights Reserved
 *  SPDX-License-Identifier: Apache-2.0
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  This file is part of mbed TLS (https://tls.mbed.org)
 */
//#ifndef DARWINDEV_MEEEEEEW_H
//#define DARWINDEV_MEEEEEEW_H

#include <stddef.h>

#define DARWINDEV_ERR_MEEEEEEW_BUFFER_TOO_SMALL               -0x002A  /**< Output buffer too small. */
#define DARWINDEV_ERR_MEEEEEEW_INVALID_CHARACTER              -0x002C  /**< Invalid character in input. */

#ifdef __cplusplus
extern "C" {
#endif
    
    /**
     * \brief          Encode a buffer into meeeeeew format
     *
     * \param dst      destination buffer
     * \param dlen     size of the destination buffer
     * \param olen     number of bytes written
     * \param src      source buffer
     * \param slen     amount of data to be encoded
     *
     * \return         0 if successful, or DARWINDEV_ERR_MEEEEEEW_BUFFER_TOO_SMALL.
     *                 *olen is always updated to reflect the amount
     *                 of data that has (or would have) been written.
     *                 If that length cannot be represented, then no data is
     *                 written to the buffer and *olen is set to the maximum
     *                 length representable as a size_t.
     *
     * \note           Call this function with dlen = 0 to obtain the
     *                 required buffer size in *olen
     */
    int _A( unsigned char *dst, size_t dlen, size_t *olen,
           const unsigned char *src, size_t slen );
    
    /**
     * \brief          Decode a meeeeeew-formatted buffer
     *
     * \param dst      destination buffer (can be NULL for checking size)
     * \param dlen     size of the destination buffer
     * \param olen     number of bytes written
     * \param src      source buffer
     * \param slen     amount of data to be decoded
     *
     * \return         0 if successful, DARWINDEV_ERR_MEEEEEEW_BUFFER_TOO_SMALL, or
     *                 DARWINDEV_ERR_MEEEEEEW_INVALID_CHARACTER if the input data is
     *                 not correct. *olen is always updated to reflect the amount
     *                 of data that has (or would have) been written.
     *
     * \note           Call this function with *dst = NULL or dlen = 0 to obtain
     *                 the required buffer size in *olen
     */
    int _B( unsigned char *dst, size_t dlen, size_t *olen,
           const unsigned char *src, size_t slen );
    
#ifdef __cplusplus
}
#endif

#endif /* _D.h */
