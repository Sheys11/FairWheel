//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract ProtocolFeesManager {
/* Fees will be different for every pools, bottom Ts will have lower fees like %0.09 percent
 tier 9 - %0.5
 tier 8 - %0.8
 tier 7 - %1
 tier 6 - %1.5
 tier 5 - %2
 tier 4 - %3.5
 tier 3 - %5
 tier 2 - %10
 tier 1 - %15

 tier 1 and 2 will have different choices like bid on gold traits, collection speci fics(organisations - Yuga or from BAYC/MAYC/Punks and other bluechips or collections from real independent artists), special query/filter options.


 tier 1 -5's or all tier's bidincreasepercentage will change too. Higher percentage per bid, in respect to demand. If tier 1 receives more bids, minIncreasepercentage will increase, if less, it'will reduce.

 per 5 additional bids : add 0.15% pecent
 1 bid on pool adds 0.09%
 every bid on pool adds 0.09% increase to pool bipr


 average bipr per tiers (fixed can't go below)
 bottom_t - 0.5% 300d 30d 3d 1.5d 301.5d 5 - 10d added value.  
 tier9 - 0.5%
 tier8 - 0.5%
 tier7 - 0.7% 2kd 200d 20d 16d
 tier6 - 0.8% 30kd 3kd 300d 230d
 tier5 - 0.9% 40kd 4kd 400d 350d
 tier4 - 1% 60kd 6kd 600d
 tier3 - 2% 80kd 8kd 1.6kd
 tier2 - 3% 100kd 10kd 3kd     atleast/most 3k added
 tier1 - 5% 200kd 20kd 10kd    atleast 10k added 

 a bid adds : 0.1% of bipr
 tier1 adds: 5% of bipr
 tier2 adds:  


All tier 1 - 3 should probably offer royalties or have a good community. The artworks will be top tier. Might need a good community name or be a cllection of a renowned artist to sell in tier one.

That's while fairwheel is for resale. The nfts we will allow in these tiers must be top notch, blue chips.

Launchpads can be allowed in tier 8 - 10;

 sell $1m - we receive $150k
 sell $10m - we receive $1.5m
 sell $90m - we receive $13.5m
*/
}