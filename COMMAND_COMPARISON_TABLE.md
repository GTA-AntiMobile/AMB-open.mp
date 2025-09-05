# Command Comparison Table - Critical Issues

## 🔴 CRITICAL: Duplicate Commands Table

| Command Name | Occurrences | System | Risk Level | Action Required | Fixed?
|--------------|-------------|--------|------------|----------------|  ----------------|
| **repair** | 4 times | Vehicle | 🔴 CRITICAL | Merge implementations | X
| **setarmor** | 4 times | Admin | 🔴 CRITICAL | Remove duplicates | X
| **sethp** | 4 times | Admin | 🔴 CRITICAL | Remove duplicates | X
| **stopanim** | 4 times | Animation | 🔴 CRITICAL | Remove duplicates | X
| **911** | 3 times | Emergency | 🟠 HIGH | Consolidate handlers | X
| **arrest** | 3 times | Police | 🟠 HIGH | Fix conflict | X
| **balance** | 3 times | Banking | 🟠 HIGH | Unify banking logic | X
| **call** | 3 times | Phone | 🟠 HIGH | Fix phone system |
| **contacts** | 3 times | Phone | 🟠 HIGH | Remove duplicates |
| **cuff** | 3 times | Police | 🟠 HIGH | Consolidate police tools |
| **f** | 3 times | Family | 🟠 HIGH | Fix family chat |
| **fly** | 3 times | Admin | 🟠 HIGH | Admin tool conflict |
| **fuel** | 3 times | Vehicle | 🟠 HIGH | Vehicle system issue |
| **givemoney** | 3 times | Economy | 🟠 HIGH | Economy conflict |
| **giveweapon** | 3 times | Admin | 🟠 HIGH | Admin weapon tool |
| **hangup** | 3 times | Phone | 🟠 HIGH | Phone system |
| **jetpack** | 3 times | Admin | 🟠 HIGH | Admin tool |
| **lock** | 3 times | Vehicle | 🟠 HIGH | Vehicle security |
| **pickup** | 3 times | Phone | 🟠 HIGH | Phone system |
| **radio** | 3 times | Communication | 🟠 HIGH | Radio system |
| **report** | 3 times | Admin | 🟠 HIGH | Report system |
| **searchcar** | 3 times | Police | 🟠 HIGH | Police search |
| **setmyarmor** | 3 times | Admin | 🟠 HIGH | Admin tool |
| **setmyhp** | 3 times | Admin | 🟠 HIGH | Admin tool |
| **sms** | 3 times | Phone | 🟠 HIGH | Phone messaging |
| **spec** | 3 times | Admin | 🟠 HIGH | Admin spectate |
| **stats** | 3 times | Player | 🟠 HIGH | Player info | X
| **ticket** | 3 times | Police | 🟠 HIGH | Police tickets |
| **time** | 3 times | Server | 🟠 HIGH | Time system |
| **withdraw** | 3 times | Banking | 🟠 HIGH | Banking system |

## 🟡 HIGH PRIORITY: Missing Core Commands

| SA-MP Command | Category | Importance | Vietnamese Name | Function |
|---------------|----------|------------|-----------------|----------|
| **ac** | Admin | 🔴 CRITICAL | Anti-cheat | Admin cheat detection |
| **admin** | Admin | 🔴 CRITICAL | Admin panel | Main admin interface |
| **adjust** | Admin | 🔴 CRITICAL | Player adjustment | Modify player data |
| **badge** | Police | 🔴 CRITICAL | Police badge | Show police ID |
| **baocao** | Report | 🔴 CRITICAL | Report system | Vietnamese report |
| **baolanh** | Legal | 🔴 CRITICAL | Bail system | Vietnamese bail |
| **bancuahang** | Business | 🟠 HIGH | Business ban | Vietnamese business ban |
| **bangiap** | Business | 🟠 HIGH | License ban | Vietnamese permit ban |
| **bannhatoi** | Property | 🟠 HIGH | House ban | Vietnamese house ban |
| **banvukhi** | Weapons | 🟠 HIGH | Weapon ban | Vietnamese weapon ban |
| **banxetoi** | Vehicle | 🟠 HIGH | Vehicle ban | Vietnamese vehicle ban |
| **apply** | Admin | 🟠 HIGH | Application | Job application |
| **achuyenkhoan** | Banking | 🟠 HIGH | Transfer admin | Admin bank transfer |
| **addmaterials** | Crafting | 🟠 HIGH | Add materials | Crafting system |
| **ads** | Economy | 🟠 HIGH | Advertisements | Advertisement system |
| **aimpound** | Admin | 🟠 HIGH | Admin impound | Admin vehicle impound |
| **amotd** | Admin | 🟠 HIGH | Admin MOTD | Message of the day |
| **apark** | Admin | 🟠 HIGH | Admin park | Admin parking |
| **armornear** | Equipment | 🟠 HIGH | Nearby armor | Armor near player |
| **asellbiz** | Admin | 🟠 HIGH | Admin sell biz | Admin business sale |
| **asellhouse** | Admin | 🟠 HIGH | Admin sell house | Admin house sale |
| **ataxi** | Transport | 🟠 HIGH | Admin taxi | Admin taxi system |

## 🟢 MEDIUM PRIORITY: System Extensions

| SA-MP Command | Category | Status | Notes |
|---------------|----------|---------|-------|
| **backup** | Emergency | Missing | Backup request system |
| **barrel** | Objects | Missing | Barrel placement |
| **camera** | Media | Missing | Camera system |
| **contract** | Legal | Missing | Contract system |
| **divorce** | Legal | Missing | Marriage divorce |
| **editveh** | Vehicle | Missing | Vehicle editing |
| **family** | Social | Partial | Family management |
| **gatepw** | Security | Missing | Gate password |
| **helper** | Support | Missing | Helper system |
| **insurance** | Economy | Missing | Insurance system |

## 🔧 MTA Enhancement Commands (New Features)

| MTA Command | Category | Purpose | SA-MP Equivalent |
|-------------|----------|---------|------------------|
| **neon** | Vehicle | Neon lights | None |
| **nitro** | Vehicle | Nitrous system | None |
| **drift** | Vehicle | Drift mode | None |
| **arena** | Gaming | Arena system | None |
| **lottery** | Economy | Lottery system | None |
| **voice** | Communication | Voice chat | None |
| **navigation** | Utility | GPS navigation | None |
| **court** | Legal | Court system | Enhanced |
| **turf** | Gang | Territory war | Enhanced |
| **race** | Gaming | Racing system | Enhanced |

## 📋 Action Plan Summary

### Immediate Actions (Week 1):
1. **Fix 4x duplicates**: repair, setarmor, sethp, stopanim
2. **Resolve 3x duplicates**: 30 critical commands
3. **Test core systems**: Banking, Police, Phone, Admin

### Short-term Actions (Week 2-3):
1. **Migrate missing admin tools**: ac, admin, adjust, badge
2. **Implement Vietnamese commands**: baocao, baolanh, ban* series
3. **Fix 2x duplicates**: 100+ medium priority commands

### Long-term Actions (Week 4+):
1. **Complete missing systems**: 889 remaining commands
2. **Validate MTA enhancements**: 292 new commands  
3. **Performance optimization and testing**

---

*Detailed analysis of 1,315 commands requiring attention*  
*Priority: Fix duplicates first, then migrate missing core functionality*
