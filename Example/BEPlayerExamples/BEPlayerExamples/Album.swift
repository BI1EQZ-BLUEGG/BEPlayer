//
//  Album.swift
//  BEPlayerExamples
//
//  Created by bluegg on 2024/12/7.
//

import Foundation
let mediaURLs1 = [
    "https://m801.music.126.net/20241208005801/8c2481644b1dfc1d911627eac4aa7a4c/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/30440974542/682b/f4d5/8f5f/8b1a60af6a9f0012cd87e7a8bb10efd5.mp3",
    "https://m10.music.126.net/20241208005840/b56fe9c7ea46f90ac9f2f4da10ddca92/ymusic/de0f/5703/a47b/a44e45d3b04e5a13419d54da4b1c554f.mp3",
]
let mediaURLs = [
    "http://cdn.yixi.tv/1551767800662-3.mp4",
    "http://cdn.yixi.tv/1552224005367-3.mp4",
    "http://cdn.yixi.tv/o_1blsg0hkan3h19lu1ubvomv1ejlg-3.mp4",
    "http://cdn.yixi.tv/o_1bls80p56du71jpj1c8i1qem1fbcg-3.mp4",
    "http://cdn.yixi.tv/o_1bmedg1bn115m1s4r1duq1vt9108ua-3.mp4",
    "http://cdn.yixi.tv/1545629913111-3.mp4",
    "http://cdn.yixi.tv/o_1cmkrdmea5sv3a6140kk6j1gri9-3.mp4",
    "http://cdn.yixi.tv/o_1cl3apuurul87l41t61ppb1pc99-3.mp4",
    "http://cdn.yixi.tv/o_1cgosr8un1ako1rg1s5o15e61hqsg-3.mp4",
    "http://cdn.yixi.tv/o_1c24eujs61vnq1vqvkel1nbgsgtg-3.mp4",
    "http://cdn.yixi.tv/o_1bqcu5icnmgl18g01upl1oe49e2g-3.mp4",
    "http://cdn.yixi.tv/o_1bo9a4aio1rfc59cois1du82bdg-3.mp4",
    "http://cdn.yixi.tv/o_1bn83l40e16oca3h895shbkfdg-3.mp4",
    "http://cdn.yixi.tv/o_1bj9hlvg61grhe3310if19rk5gvg-3.mp4",
    "http://cdn.yixi.tv/o_1bj9mri3g65tks9odb5n3j9g-3.mp4",
    "http://cdn.yixi.tv/o_1bjke2h7l1rm81igs217oit1d1jg-3.mp4",
    "http://cdn.yixi.tv/o_1bjnddctf23pkhe1pf6llcgfvg-3.mp4",
    "http://cdn.yixi.tv/o_1bjn2uolojrp13op19st1uocbpcg-3.mp4",
    "http://cdn.yixi.tv/o_1bjn1ac3c2l71sqgut487nuddg-3.mp4",
    "http://cdn.yixi.tv/o_1bjpncc2tmnd1ulm1frlg4q1rc8g-3.mp4",
    "http://cdn.yixi.tv/o_1boccfb1c1rtv1epu1s861bk417bkg-3.mp4",
    "http://cdn.yixi.tv/o_1bk3fp13qfbr145o1lj71e3v10fsg-3.mp4",
    "http://cdn.yixi.tv/1541583475783-3.mp4",
    "http://cdn.yixi.tv/1540540450065-3.mp4",
    "http://cdn.yixi.tv/o_1cff0ccjf1saf1uq21qoi1c1qrd2g-3.mp4",
    "http://cdn.yixi.tv/o_1cbka6qmnvqs8u22dj13ttqk0g-3.mp4",
    "http://cdn.yixi.tv/o_1c7svl8kg1gbbcrufdq1egn1aj7g-3.mp4",
    "http://cdn.yixi.tv/o_1bvch4egt6961980e8u11gc1ajlg-3.mp4",
    "http://cdn.yixi.tv/o_1bsia7id18e5g3v2h21ah74dcg-3.mp4",
    "http://cdn.yixi.tv/o_1boorrrk1unv1pmcmvchn71ekcg-3.mp4",
    "http://cdn.yixi.tv/o_1bocc964h1o8k11epopn13ci756g-3.mp4",
    "http://cdn.yixi.tv/o_1boris65vucn1eoc3o97qkshrg-3.mp4",
    "http://cdn.yixi.tv/o_1bmgttu21l46ph8lt170npbfg-3.mp4",
    "http://cdn.yixi.tv/o_1bjk6ikq0d1ut1d13h31h7v1j8pg-3.mp4",
    "http://cdn.yixi.tv/o_1bjkccbf51q2ome613kl1fcgc3og-3.mp4",
    "http://cdn.yixi.tv/o_1bmbirjfr1jes1qhebq31rau1vvag-3.mp4",
    "http://cdn.yixi.tv/o_1bn36imi31pgk40c175a33h13mvg-3.mp4",
    "http://cdn.yixi.tv/o_1blv5ptstj0u1rj215bq1m00fscg-3.mp4",
    "http://cdn.yixi.tv/o_1blv32ja6154o67t96oq2q1qlg-3.mp4",
    "http://cdn.yixi.tv/o_1blv22ol09uckpagnv16ji1oeng-3.mp4",
    "http://cdn.yixi.tv/o_1blup72hr16huten1n9vqrt16kkg-3.mp4",
    "http://cdn.yixi.tv/o_1bocgfdpp1ejqk9p1eifckh1n6bg-3.mp4",
    "http://cdn.yixi.tv/o_1bn8fsb3i1hejfgi1jh81n5gsm5g-3.mp4",
    "http://cdn.yixi.tv/o_1blumv6gk1btm1i6c11jd1i0j15cjg-3.mp4",
    "http://cdn.yixi.tv/o_1bo9n6i4ujas1eq61tu91q2gf7pg-3.mp4",
    "http://cdn.yixi.tv/o_1bo4a7g3m1u0s13subh6nun18kg-3.mp4",
    "http://cdn.yixi.tv/o_1blijrjkof67usl1t55n481me8g-3.mp4",
    "http://cdn.yixi.tv/o_1bn2ng6co1i6dfp11mm1pqn1rvog-3.mp4",
    "http://cdn.yixi.tv/o_1blcuo5bq17q311f71fmnmdu1fvsg-3.mp4",
    "http://cdn.yixi.tv/o_1bko1k9dmv971tdr1gg0j22nmjg-3.mp4"
]
