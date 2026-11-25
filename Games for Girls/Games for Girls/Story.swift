import SwiftUI

struct Passenger: Codable, Identifiable, Equatable {
    var id = UUID()
    var boyName: String
    var girlName: String
    var look: Look
    var changed = false

    var name: String { changed ? girlName : boyName }

    static let names: [(String, String)] = [
        ("Tommy", "Tammy"), ("Bobby", "Bobbie"), ("Steve", "Stephanie"), ("Gary", "Gabby"), ("Mike", "Michelle"),
        ("Joey", "Josie"), ("Frankie", "Frances"), ("Paul", "Paula"), ("Eric", "Erica"), ("Carl", "Carla"),
        ("Danny Jr.", "Dana"), ("Nicky", "Nicole"), ("Pete", "Petra"), ("Willy", "Wilma"), ("Gus", "Gussie"),
        ("Andy", "Andrea"), ("Randy", "Miranda"), ("Vinnie", "Vanessa"), ("Teddy", "Teresa"), ("Louie", "Louise"),
        ("Henry", "Henrietta"), ("Georgie", "Georgia"), ("Marty", "Martina"), ("Jack", "Jackie"),
    ]

    static func random(excluding used: Set<String> = []) -> Passenger {
        let pool = names.filter { !used.contains($0.0) }
        let n = (pool.isEmpty ? names : pool).randomElement()!
        let look = Look(skin: Palette.skins.randomElement()!, hair: Palette.hairs.randomElement()!,
                        shirt: Palette.shirts.randomElement()!, pants: [[0.25, 0.25, 0.5], [0.3, 0.3, 0.3], [0.35, 0.28, 0.2], [0.15, 0.3, 0.55]].randomElement()!,
                        dress: Palette.dresses.randomElement()!,
                        boyHair: [BoyHair.short, .buzz, .curly, .spiky].randomElement()!,
                        girlHair: [GirlHair.long, .ponytail, .pigtails, .bob].randomElement()!,
                        kid: Bool.random())
        return Passenger(boyName: n.0, girlName: n.1, look: look)
    }
}

let girlNames = ["Ellie", "Christina", "Deirdre"]
let boyNames = ["Elmer", "Chris", "Danny"]

enum SceneKind {
    case momCarArrive             // Mom's car pulls up outside the arcade
    case momCarDropoff            // kids climb out, Mom waves from the driver's seat
    case bossAtCar(Mood)          // boss leans in at Mom's car window; kids beside the car
    case momMad(Int)              // Mom out of the car, angry at the boss
    case momDrivesOff
    case zamboniWork(Int)         // the boys drive 3 maintenance zambonis; 1 = boss points
    case zamboniLunch             // zambonis parked mid-job, the boys eat lunch
    case lunchVisit(Int)          // the Woman drops by at lunch: 0 walks in, 1 explains, 2 kisses each cheek, 3 leaves
    case lunchBoss                // Mr. Grubb catches them on their lunch – scowling
    case bossTantrum(Int)         // Mr. Grubb blows his top (red face, steam, stomping)
    case repoArrive, repoAskKidsOut
    case repoAskGrubb(Int)        // "Are you Mr. Grubb?" – 0 repo man, 1 Grubb answers
    case repoArgue(Mood)
    case repoFight
    case repoZambonis             // repo men drive the zambonis into the truck
    case repoLoading(Int)
    case powerCut(Int)            // 0 power truck arrives, 1 lineman at the breaker, 2 lights out
    case foreclosure
    case trikeRepo(Int)           // 0 truck hooks trike, 1 boss chases, 2 boss gone
    case trikeLaugh(Int)          // 0 boys crack up, 1 Grubb comes back panting, 2 the boys answer him, 3 Grubb stomps off
    case kidsOutOfWork
    case pierWalk                 // the boys walk out along the pier
    case pierEnd(Int)             // ship docked at the end of the pier: 0 the Woman waves, 1 the boys go up the gangway
    case shipWelcome
    case notGirls
    case secretRoom
    case strapped
    case transforming             // animated over the shot
    case mirror
    case firstGame
    case acceptJob
    case portReturn
    case homeMom(Mood)
    case homeTell(Int)
    // daily
    case morning(Int)
    case boardingPassengers
    case passengerChairs(transforming: Bool)
    case passengerMirror
    case endOfDay
    case bedrooms(asleep: Bool)   // the girls' bedrooms, redesigned for girls
    case cabins(asleep: Bool)     // the girls' cabins aboard the ship
    case vanity(Int)              // one girl admiring her new look in her bedroom mirror
    case shipMorning(Int)
    // shore excursions
    case sailing(Port, home: Bool)
    case atPort(Port)
    case customs(String?, seized: Bool)   // item emoji on the inspection table
    case shipUpgraded
    case momGifts(String?)
    // morning bank trip after a cruise night
    case bankDrive(Int)           // 0 Mom drives the girls to the bank, 1 drives them back to the pier
    case bankLobby(Int)           // inside Boardwalk Bank; 0–2 = that girl at the teller window, else everyone waits
}

struct Shot {
    var scene: SceneKind
    var speaker: String? = nil
    var text: String
    var voice: Sound.Voice = .narrator
    var sfx: Sound.Effect? = nil
    /// seconds the shot's own animation runs for (transform, ship arrival, …)
    var anim: Double = 2.5
}

enum Story {
    static func prologue() -> [Shot] {
        [
            Shot(scene: .momCarArrive, text: "Saturday morning. Mom drives Elmer, Chris and Danny to their jobs at the Fun Zone Arcade on the boardwalk.", sfx: .truck, anim: 3),
            Shot(scene: .momCarDropoff, speaker: "Mom", text: "Have a good day at work, boys! I'll pick you up tonight.", voice: .mom),
            Shot(scene: .bossAtCar(.angry), text: "Before Mom can pull away, the boss, Mr. Grubb, stomps over to her car.", sfx: .click),
            Shot(scene: .bossAtCar(.angry), speaker: "Mr. Grubb", text: "No arcade duty for you three today. You're on maintenance! Take the maintenance zambonis and scrub every floor in this arcade!", voice: .boss),
            Shot(scene: .bossAtCar(.sad), speaker: "Elmer", text: "But Mr. Grubb, we're supposed to be working the prize counter today.", voice: .boy),
            Shot(scene: .bossAtCar(.angry), speaker: "Mr. Grubb", text: "Maintenance! And when you're done with that, there's more maintenance.", voice: .boss),
            Shot(scene: .momMad(0), text: "Mom's door flies open and she gets out of the car.", sfx: .crash),
            Shot(scene: .momMad(0), speaker: "Mom", text: "Excuse me? You hired my boys to work in the arcade, not to drive your zambonis around all day!", voice: .mom),
            Shot(scene: .momMad(1), speaker: "Mr. Grubb", text: "My arcade, my rules, lady. If they don't like it, they can find another job.", voice: .boss),
            Shot(scene: .momMad(0), speaker: "Mom", text: "Don't you lady me! You treat my kids right, or you'll be hearing from me!", voice: .mom),
            Shot(scene: .momMad(1), speaker: "Mr. Grubb", text: "Yeah, yeah. Inside, you three. The zambonis are by the back door.", voice: .boss),
            Shot(scene: .momDrivesOff, text: "Mom gets back in her car and drives off, still fuming.", sfx: .truck, anim: 3),
            Shot(scene: .zamboniWork(0), text: "Inside, the boys climb onto three maintenance zambonis and start scrubbing the arcade floors.", sfx: .mop, anim: 4),
            Shot(scene: .zamboniWork(0), speaker: "Chris", text: "Vroom! At least we get to drive something.", voice: .boy, sfx: .mop),
            Shot(scene: .zamboniLunch, text: "Halfway through the job, the noon whistle blows. The boys park their zambonis and open their lunch boxes.", sfx: .horn),
            Shot(scene: .zamboniLunch, speaker: "Danny", text: "Lunch time! I'm starving.", voice: .boy),
            Shot(scene: .lunchVisit(0), text: "While they eat, a woman in a sparkling pink dress walks into the arcade and comes right over to the boys.", sfx: .sparkle, anim: 3),
            Shot(scene: .lunchVisit(1), speaker: "The Woman", text: "Hello boys! I have a cruise ship docked at the end of the pier, and I'm looking for a crew.", voice: .hostess),
            Shot(scene: .lunchVisit(1), speaker: "The Woman", text: "Here's my offer. You'd invite passengers aboard every day, play board games, card games and dice games with them, and keep a share of the profits.", voice: .hostess),
            Shot(scene: .lunchVisit(1), speaker: "Elmer", text: "Playing games all day? That beats driving zambonis for Mr. Grubb!", voice: .boy),
            Shot(scene: .lunchVisit(1), speaker: "Chris", text: "What's the ship called?", voice: .boy),
            Shot(scene: .lunchVisit(1), speaker: "The Woman", text: "You'll see when you get there. Whenever you're ready, just come to the end of the pier.", voice: .hostess),
            Shot(scene: .lunchVisit(1), speaker: "The Woman", text: "Don't answer me now. Think about it, boys.", voice: .hostess),
            Shot(scene: .lunchVisit(2), text: "Before she goes, she gives each of them a kiss on the cheek.", sfx: .sparkle, anim: 6),
            Shot(scene: .lunchVisit(3), speaker: "Danny", text: "She kissed me!", voice: .boy, anim: 3),
            Shot(scene: .lunchBoss, text: "Mr. Grubb storms in and sees the boys on their lunch. His face twists into a furious scowl.", sfx: .crash),
            Shot(scene: .lunchBoss, speaker: "Mr. Grubb", text: "What is this?! Why are my zambonis just sitting there?!", voice: .boss),
            Shot(scene: .lunchBoss, speaker: "Elmer", text: "We don't work during our lunch.", voice: .boy),
            Shot(scene: .lunchBoss, speaker: "Chris", text: "Everyone else is on lunch, too!", voice: .boy),
            Shot(scene: .bossTantrum(0), text: "Mr. Grubb's face turns as red as a tomato. Steam shoots out of his ears, and he jumps up and down, stomping his feet!", sfx: .crash, anim: 3),
            Shot(scene: .bossTantrum(1), speaker: "Mr. Grubb", text: "Lunch is over when I say it's over! Get back on those zambonis, NOW!", voice: .boss),
            Shot(scene: .bossTantrum(2), speaker: "Danny", text: "Uh-oh. I think we really made him mad.", voice: .boy),
            Shot(scene: .repoArrive, text: "Just then, a big truck backs up to the arcade door.", sfx: .truck),
            Shot(scene: .repoAskKidsOut, speaker: "Repo Man", text: "Okay kids, we need you to exit the building, please.", voice: .repo),
            Shot(scene: .repoAskGrubb(0), speaker: "Repo Man", text: "Are you Mr. Grubb?", voice: .repo),
            Shot(scene: .repoAskGrubb(1), speaker: "Mr. Grubb", text: "Yeah, I'm Mr. Grubb. Who wants to know?", voice: .boss),
            Shot(scene: .repoAskGrubb(0), speaker: "Repo Man", text: "These zambonis are up for repossession, and so are your games.", voice: .repo),
            Shot(scene: .repoArgue(.angry), text: "Mr. Grubb's face turns bright red.", sfx: .crash),
            Shot(scene: .repoArgue(.angry), speaker: "Repo Man", text: "Sir, you need to calm down.", voice: .repo),
            Shot(scene: .repoFight, text: "But Mr. Grubb starts fighting them!", sfx: .crash),
            Shot(scene: .repoFight, speaker: "Repo Man", text: "Sir, you need to back off, or we are calling the police.", voice: .repo, sfx: .crash),
            Shot(scene: .repoZambonis, text: "The repo men drive the three zambonis right up the ramp into the truck…", sfx: .truck, anim: 4),
            Shot(scene: .repoLoading(2), text: "The repo men roll the games out one by one…", sfx: .truck),
            Shot(scene: .repoLoading(6), text: "…until the arcade is empty.", sfx: .truck),
            Shot(scene: .powerCut(0), text: "As the repo truck pulls away, a power company truck pulls up.", sfx: .truck, anim: 3),
            Shot(scene: .powerCut(1), speaker: "Power Company Man", text: "Mr. Grubb? Power company. Your electric bill hasn't been paid in months, so we're turning off your lights.", voice: .bank),
            Shot(scene: .powerCut(1), speaker: "Mr. Grubb", text: "No, no, no! Not my lights too!", voice: .boss),
            Shot(scene: .powerCut(2), text: "CLUNK! He pulls the switch, and the Fun Zone Arcade goes dark.", sfx: .click),
            Shot(scene: .foreclosure, speaker: "Bank Representative", text: "Mr. Grubb, we're from the bank. This arcade is now in foreclosure. We're locking the doors.", voice: .bank),
            Shot(scene: .foreclosure, speaker: "Bank Representative", text: "You kids need to go home.", voice: .bank),
            Shot(scene: .trikeRepo(0), speaker: "Repo Man", text: "And one more thing – we're here for the trike, too.", voice: .repo, sfx: .truck),
            Shot(scene: .trikeRepo(1), speaker: "Mr. Grubb", text: "Hey! Come back with my trike!", voice: .boss, anim: 3),
            Shot(scene: .trikeRepo(2), text: "Mr. Grubb runs after it down the boardwalk, huffing and puffing…", anim: 3),
            Shot(scene: .trikeLaugh(0), text: "The boys burst out laughing! They laugh so hard they have to hold their stomachs.", anim: 3),
            Shot(scene: .trikeLaugh(0), speaker: "Danny", text: "Did you see him chasing that truck?!", voice: .boy),
            Shot(scene: .trikeLaugh(0), speaker: "Elmer", text: "His little legs were going a mile a minute!", voice: .boy),
            Shot(scene: .trikeLaugh(1), text: "A few minutes later, Mr. Grubb comes trudging back up the boardwalk – sweaty, out of breath, and with no trike.", anim: 4),
            Shot(scene: .trikeLaugh(1), speaker: "Mr. Grubb", text: "Laugh it up, you little brats! They took my trike! Now how am I supposed to get home?!", voice: .boss),
            Shot(scene: .trikeLaugh(2), speaker: "Chris", text: "Well if you don't pay your bills, this is what happens to your ass.", voice: .boy),
            Shot(scene: .trikeLaugh(3), text: "Mr. Grubb's face goes red as a beet. He stomps off down the boardwalk on foot – and he never comes back.", sfx: .crash, anim: 3),
            Shot(scene: .kidsOutOfWork, speaker: "Danny", text: "Well… I guess we're out of work now.", voice: .boy),
            Shot(scene: .kidsOutOfWork, speaker: "Elmer", text: "What about that lady's offer? She said her ship is at the end of the pier!", voice: .boy),
            Shot(scene: .pierWalk, text: "The three boys walk all the way out to the end of the pier.", anim: 5),
            Shot(scene: .pierEnd(0), text: "A pink cruise ship is docked there, and the woman is waiting at the gangway.", sfx: .horn, anim: 2),
            Shot(scene: .pierEnd(0), speaker: "The Woman", text: "Hello again, boys! I knew you'd come. Come aboard!", voice: .hostess),
            Shot(scene: .pierEnd(1), text: "The boys walk up the gangway and board the ship.", anim: 4),
            Shot(scene: .shipWelcome, speaker: "The Woman", text: "Welcome to Games for Girls.", voice: .hostess, sfx: .sparkle),
            Shot(scene: .notGirls, speaker: "Elmer, Chris and Danny", text: "But we are not girls.", voice: .boy),
            Shot(scene: .notGirls, speaker: "The Woman", text: "Oh, that's easy to fix. Follow me to the secret room.", voice: .hostess),
            Shot(scene: .secretRoom, text: "Behind a pink door are three chairs with shiny helmets hanging over them.", sfx: .click),
            Shot(scene: .strapped, text: "The boys sit down and straps snap across them. The helmets lower.", sfx: .click),
            Shot(scene: .transforming, text: "The machine hums and glows pink…", sfx: .machine, anim: 6),
            Shot(scene: .transforming, speaker: "Danny", text: "We're all turning into girls!", voice: .girl, sfx: .sparkle, anim: 0.01),
            Shot(scene: .mirror, text: "The straps pop open and they run to the mirror.", sfx: .sparkle),
            Shot(scene: .mirror, speaker: "The Woman", text: "Elmer, you are now Ellie. Chris, you are Christina. And Danny, you are Deirdre.", voice: .hostess),
            Shot(scene: .firstGame, speaker: "The Woman", text: "Now – let's play your first game together!", voice: .hostess),
        ]
    }

    static func afterFirstGame() -> [Shot] {
        [
            Shot(scene: .acceptJob, speaker: "The Woman", text: "You girls are naturals. Will you work for me? Bring passengers aboard each day, and we play games on the cruise.", voice: .hostess),
            Shot(scene: .acceptJob, speaker: "Ellie", text: "We accept!", voice: .girl, sfx: .coin),
            Shot(scene: .portReturn, text: "The ship returns them to the port.", sfx: .horn, anim: 3),
            Shot(scene: .homeMom(.surprised), speaker: "Mom", text: "Who are you girls? And where are Elmer, Chris and Danny?", voice: .mom),
            Shot(scene: .homeTell(0), speaker: "Ellie", text: "Mom, it's us! Mr. Grubb's arcade got repossessed and foreclosed…", voice: .girl),
            Shot(scene: .homeTell(1), speaker: "Christina", text: "…then a pink cruise ship picked us up, and a machine turned us into girls!", voice: .girl),
            Shot(scene: .homeTell(2), speaker: "Deirdre", text: "And now we have a new job: Games for Girls cruises!", voice: .girl),
            Shot(scene: .homeMom(.surprised), speaker: "Mom", text: "And what happened to that awful Mr. Grubb?", voice: .mom),
            Shot(scene: .homeTell(0), speaker: "Ellie", text: "The repo men took his trike, so he had to walk home. He never came back.", voice: .girl),
            Shot(scene: .homeTell(1), speaker: "Christina", text: "Good riddance to bad rubbish.", voice: .girl),
            Shot(scene: .homeMom(.happy), speaker: "Mom", text: "Well! I always wanted daughters. Get some sleep – you have a cruise tomorrow.", voice: .mom),
            Shot(scene: .homeMom(.happy), speaker: "Mom", text: "Oh, and one more thing. A lady from a pink cruise ship came by this afternoon with a team of decorators. Go look at your bedrooms!", voice: .mom),
            Shot(scene: .bedrooms(asleep: false), text: "The girls open their bedroom doors. Their rooms have been redesigned for girls – pink walls, canopy beds, vanity mirrors and twinkle lights!", sfx: .sparkle),
            Shot(scene: .bedrooms(asleep: false), speaker: "Deirdre", text: "The woman from the ship did this for us!", voice: .girl),
            Shot(scene: .bedrooms(asleep: false), speaker: "Christina", text: "I love it!", voice: .girl),
            Shot(scene: .bedrooms(asleep: true), text: "Ellie, Christina and Deirdre climb into their new beds. Goodnight, girls!", anim: 3),
        ]
    }

    /// Before lights-out (every night after the first), each girl stops at her vanity mirror to admire her new look.
    static func mirrorShots() -> [Shot] {
        let lines: [[String]] = [
            ["Look at my long, shiny curls! I still can't believe that's really me.",
             "Hello, beautiful! This dress looks even prettier in the mirror.",
             "Long curls, sparkly dress… goodnight, Ellie. You look lovely!"],
            ["My pigtails are perfect! And look at these big eyelashes!",
             "Mirror, mirror on the wall – who's the cutest of them all? Me!",
             "I could look at these curls all night. Okay, just one more twirl!"],
            ["My ponytail swings when I turn my head – watch!",
             "Who's that pretty girl in the mirror? Oh, it's me – Deirdre!",
             "Look at my sparkly dress! I'm going to dream about it all night."],
        ]
        var s = [Shot(scene: .vanity(0), text: "Before bed, the girls stop at their vanity mirrors to admire their new looks.", sfx: .sparkle)]
        for i in 0..<3 {
            s.append(Shot(scene: .vanity(i), speaker: girlNames[i], text: lines[i].randomElement()!, voice: .girl, sfx: i == 0 ? nil : .sparkle))
        }
        return s
    }

    static func morning(day: Int, game: String) -> [Shot] {
        [
            Shot(scene: .morning(day), speaker: "Mom", text: "Good morning, girls! Day \(day) of the Games for Girls cruises. Have fun!", voice: .mom),
        ]
    }

    static func boarding(_ ps: [Passenger], game: String) -> [Shot] {
        let names = ps.map(\.boyName)
        let list = ListFormatter.localizedString(byJoining: names)
        let girls = ListFormatter.localizedString(byJoining: ps.map(\.girlName))
        var shots = [
            Shot(scene: .boardingPassengers, text: "\(list) walk up the gangway onto the ship.", sfx: .horn),
            Shot(scene: .boardingPassengers, speaker: "The Woman", text: "Welcome to Games for Girls! Today's game is \(game).", voice: .hostess),
            Shot(scene: .boardingPassengers, speaker: ps[0].boyName, text: "But we're not girls!", voice: .boy),
            Shot(scene: .boardingPassengers, speaker: "Ellie", text: "We weren't either. Come with us to the secret room.", voice: .girl),
            Shot(scene: .passengerChairs(transforming: false), text: "The passengers are strapped into the chairs and the helmets lower.", sfx: .click),
            Shot(scene: .passengerChairs(transforming: true), text: "The machine hums and glows pink…", sfx: .machine, anim: 5),
        ]
        shots.append(Shot(scene: .passengerChairs(transforming: true), speaker: ps[0].girlName, text: ps.count > 1 ? "We're all turning into girls!" : "I'm turning into a girl!", voice: .girl, sfx: .sparkle, anim: 0.01))
        shots.append(Shot(scene: .passengerMirror, speaker: "The Woman", text: "Say hello to \(girls)! Now, to the game lounge.", voice: .hostess, sfx: .sparkle))
        return shots
    }

    static func shareShots(profit: Int, share: Int, savings: [Int], payer: String, voice: Sound.Voice, scene: SceneKind) -> [Shot] {
        guard share > 0 else {
            return [Shot(scene: scene, speaker: payer, text: profit < 0 ? "You spent more than you made today, so there's no profit to share. Maybe tomorrow!" : "There's no profit to share today. Maybe tomorrow!", voice: voice)]
        }
        return [
            Shot(scene: scene, speaker: payer, text: "Today's profit was $\(profit). Fair's fair – the business keeps one share, and each of you girls gets an equal share of $\(share)!", voice: voice, sfx: .coin),
            Shot(scene: scene, text: "Ellie now has $\(savings[0]) saved, Christina has $\(savings[1]), and Deirdre has $\(savings[2]).", sfx: .coin),
        ]
    }

    static func endOfDay(day: Int, earned: Int, cash: Int, gifts: [String] = [], profit: Int = 0, share: Int = 0, savings: [Int] = [0, 0, 0]) -> [Shot] {
        [
            Shot(scene: .portReturn, text: "The ship returns to port for the night.", sfx: .horn, anim: 3),
            Shot(scene: .endOfDay, speaker: "Mom", text: "Welcome home, girls! You took in $\(earned) today.", voice: .mom, sfx: .coin),
        ] + shareShots(profit: profit, share: share, savings: savings, payer: "Mom", voice: .mom, scene: .endOfDay) + [
            Shot(scene: .endOfDay, speaker: "Mom", text: "That leaves $\(cash) in the business bank.", voice: .mom),
        ] + giftShots(gifts) + [
            Shot(scene: .endOfDay, speaker: "Mom", text: "Now off to bed!", voice: .mom),
        ] + mirrorShots() + [
            Shot(scene: .bedrooms(asleep: true), text: "The girls snuggle into their canopy beds in their pretty new rooms. Goodnight!", anim: 3),
        ]
    }

    static func nightOnShip(earned: Int, cash: Int, profit: Int = 0, share: Int = 0, savings: [Int] = [0, 0, 0]) -> [Shot] {
        [
            Shot(scene: .cabins(asleep: false), speaker: "The Woman", text: "Tonight you'll stay aboard, girls. Each of you has your very own cabin.", voice: .hostess, sfx: .sparkle),
        ] + shareShots(profit: profit, share: share, savings: savings, payer: "The Woman", voice: .hostess, scene: .cabins(asleep: false)) + [
            Shot(scene: .cabins(asleep: false), speaker: "Ellie", text: "Look – you can see the ocean through the porthole!", voice: .girl),
            Shot(scene: .cabins(asleep: false), text: "Ellie calls Mom to say they're sleeping on the ship tonight. They earned $\(earned) today – $\(cash) in the bank.", sfx: .coin),
            Shot(scene: .cabins(asleep: true), text: "The ship rocks gently on the waves as the girls fall asleep. Goodnight!", anim: 3),
        ]
    }

    /// The morning after a cruise night: Mom takes the girls to Boardwalk Bank, each deposits some of her money.
    static func bankTrip(fromShip: Bool, deposits: [Int], pocket: [Int], bank: [Int]) -> [Shot] {
        var s: [Shot] = []
        if fromShip {
            s.append(Shot(scene: .bankDrive(0), text: "Mom is waiting in her car at the end of the pier. \"Good morning, girls! Before your cruises, we're going to the bank.\"", sfx: .truck, anim: 3))
        } else {
            s.append(Shot(scene: .bankDrive(0), speaker: "Mom", text: "Before your cruises, girls, we're going to the bank. Time to deposit some of your money!", voice: .mom, sfx: .truck, anim: 3))
        }
        s += [
            Shot(scene: .bankLobby(-1), text: "Mom and the girls walk into Boardwalk Bank and get in line at the teller's window.", sfx: .click),
            Shot(scene: .bankLobby(-1), speaker: "Bank Teller", text: "Good morning! How can I help you today?", voice: .teller),
            Shot(scene: .bankLobby(-1), speaker: "Mom", text: "My daughters would each like to make a deposit into their savings accounts.", voice: .mom),
        ]
        for i in 0..<3 where deposits[i] > 0 {
            let keep = pocket[i] > 0 ? " I'll keep $\(pocket[i]) for spending money." : ""
            s.append(Shot(scene: .bankLobby(i), speaker: girlNames[i], text: "I'd like to deposit $\(deposits[i]), please.\(keep)", voice: .girl))
            s.append(Shot(scene: .bankLobby(i), speaker: "Bank Teller", text: "Thank you, \(girlNames[i])! Your account balance is now $\(bank[i]).", voice: .teller, sfx: .coin))
        }
        s += [
            Shot(scene: .bankLobby(-1), speaker: "Mom", text: "I'm so proud of you girls. A little in the bank every day really adds up!", voice: .mom),
            Shot(scene: .bankDrive(1), text: "Mom drives the girls back to the pier, where the ship is waiting.", sfx: .truck, anim: 3),
            Shot(scene: .bankDrive(1), speaker: "Mom", text: "Have a great day on the ship, girls!", voice: .mom, sfx: .horn),
        ]
        return s
    }

    static func shipMorning(day: Int) -> [Shot] {
        [
            Shot(scene: .shipMorning(day), speaker: "The Woman", text: "Good morning, girls! Rise and shine – it's day \(day) of the Games for Girls cruises, and we're back at the boardwalk.", voice: .hostess, sfx: .horn),
        ]
    }
}

// MARK: - Scene drawing

struct SceneContext {
    var passengers: [Passenger] = []

    /// Who's saying the current line, so their mouth moves.
    func talkers(_ speaker: String?) -> [Look] {
        guard let speaker else { return [] }
        switch speaker {
        case "Mr. Grubb": return [Cast.boss]
        case "Repo Man": return [Cast.repo1]
        case "Power Company Man": return [Cast.power]
        case "Customs Officer": return [Cast.customs]
        case "Bank Representative": return [Cast.bank1]
        case "Bank Teller": return [Cast.teller]
        case "The Woman": return [Cast.hostess]
        case "Mom": return [Cast.mom]
        case "Elmer", "Ellie": return [Cast.kids[0]]
        case "Chris", "Christina": return [Cast.kids[1]]
        case "Danny", "Deirdre": return [Cast.kids[2]]
        case "Elmer, Chris and Danny": return Cast.kids
        default: return passengers.filter { $0.boyName == speaker || $0.girlName == speaker }.map(\.look)
        }
    }
}

func drawScene(_ ctx: inout GraphicsContext, _ kind: SceneKind, size: CGSize, p: Double, t: Double, sc: SceneContext) {
    let floor = size.height * 0.88
    let kidH: CGFloat = 92
    let b = CGFloat(sin(t * 6)) * 1.5
    func kids(_ xs: [CGFloat], girl: Double, mood: Mood = .neutral, arms: Arms = .down, y: CGFloat? = nil, h: CGFloat = kidH, facing: CGFloat = 0) {
        for (i, x) in xs.enumerated() {
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: y ?? floor), h: h, girl: girl, mood: mood, arms: arms, facing: facing, bob: arms == .mop ? b * 3 : 0)
        }
    }
    func label(_ s: String, _ at: CGPoint, _ c: Color = .white, _ size: CGFloat = 11) {
        ctx.draw(Text(s).font(.system(size: size, weight: .bold, design: .rounded)).foregroundStyle(c), at: at)
    }

    switch kind {
    case .momCarArrive, .momCarDropoff, .bossAtCar, .momMad, .momDrivesOff:
        drawBoardwalk(&ctx, size)
        drawArcadeFront(&ctx, x: 250, floor: floor - 20)
        let carY = floor + 4
        switch kind {
        case .momCarArrive:
            drawCar(&ctx, x: -140 + CGFloat(min(1, p * 1.2)) * 180, ground: carY, driver: Cast.mom, driverMood: .happy, kids: true)
        case .momCarDropoff:
            drawCar(&ctx, x: 40, ground: carY, driver: Cast.mom, driverMood: .happy)
            kids([200, 235, 270], girl: 0, mood: .neutral, arms: .wave, h: 80, facing: -1)
        case .bossAtCar(let mood):
            drawCar(&ctx, x: 40, ground: carY, driver: Cast.mom, driverMood: .surprised)
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 205, y: floor), h: 120, mood: .angry, arms: .point, facing: -1, bob: mood == .angry ? b : 0)
            kids([260, 290, 320], girl: 0, mood: mood == .sad ? .sad : .surprised, h: 80, facing: -1)
        case .momMad(let who):
            drawCar(&ctx, x: 10, ground: carY, driver: nil, doorOpen: true)
            drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 175, y: floor), h: 116, mood: .angry, arms: who == 0 ? .point : .hands, facing: 1, bob: who == 0 ? b : 0)
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 245, y: floor), h: 120, mood: who == 1 ? .angry : .surprised, arms: who == 1 ? .point : .hands, facing: -1)
            kids([300, 330, 360], girl: 0, mood: .surprised, h: 80, facing: -1)
            if who == 0 { label("💢", CGPoint(x: 195, y: floor - 125), .red, 18) }
        default:
            drawCar(&ctx, x: 40 - CGFloat(p) * 260, ground: carY, driver: Cast.mom, driverMood: .angry)
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 230, y: floor), h: 120, mood: .angry, arms: .point, facing: 1)
            kids([280, 310, 340], girl: 0, mood: .sad, arms: .mop, h: 80, facing: -1)
        }
    case .zamboniWork(let n):
        drawArcade(&ctx, size)
        for (i, x) in [42.0, 165, 288].enumerated() {
            let drive = CGFloat(sin(t * 0.9 + Double(i) * 2)) * 6
            drawZamboni(&ctx, x: x + drive, floor: floor, s: 0.66, driver: Cast.kids[i], driverH: 70, mood: .neutral, t: t + Double(i))
        }
        // soapy suds trailing behind
        for k in 0..<6 {
            let u = (t * 0.5 + Double(k) / 6).truncatingRemainder(dividingBy: 1)
            ctx.fill(Path(ellipseIn: CGRect(x: 20 + CGFloat(k) * 64, y: floor - 4 - CGFloat(u) * 6, width: 10, height: 6)), with: .color(.white.opacity(0.6 * (1 - u))))
        }
        if n == 1 { drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 370, y: floor), h: 120, mood: .angry, arms: .point, facing: -1) }
    case .zamboniLunch, .lunchBoss:
        drawArcade(&ctx, size)
        drawParkedZambonis(&ctx, floor: floor, t: t)
        let boss = kind.isLunchBoss
        for (i, x) in [90.0, 165, 240].enumerated() {
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: kidH, girl: 0, mood: boss ? .surprised : .happy, arms: .hands, facing: boss ? 1 : 0)
            label("🥪", CGPoint(x: x + 10, y: floor - 46 + (boss ? 0 : CGFloat(sin(t * 3 + Double(i))) * 3)), .white, 16)
            ctx.fill(Path(roundedRect: CGRect(x: x - 26, y: floor - 12, width: 16, height: 12), cornerRadius: 2), with: .color([Color.red, .blue, .green][i]))
        }
        if boss {
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 345, y: floor), h: 122, mood: .angry, arms: .point, facing: -1, bob: b)
            label("💢", CGPoint(x: 368, y: floor - 128), .red, 20)
        }
    case .lunchVisit(let stage):
        drawArcade(&ctx, size)
        drawParkedZambonis(&ctx, floor: floor, t: t)
        let xs: [CGFloat] = [130, 205, 280]
        // stage 2 runs through the three kisses; stage 3 = all three kissed
        let kissPhase = stage == 2 ? p * 3 : (stage == 3 ? 3 : 0)
        for (i, x) in xs.enumerated() {
            let kissed = kissPhase >= Double(i) + 0.55
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: kidH, girl: 0,
                       mood: kissed ? .happy : (stage == 0 ? .surprised : .neutral), arms: .hands, facing: -1)
            if !kissed { label("🥪", CGPoint(x: x + 10, y: floor - 46), .white, 16) }
            ctx.fill(Path(roundedRect: CGRect(x: x + 12, y: floor - 12, width: 16, height: 12), cornerRadius: 2), with: .color([Color.red, .blue, .green][i]))
            if kissed {
                // rosy blush + lipstick mark on the cheek she kissed
                let r = kidH * 0.12
                let cheek = CGPoint(x: x - r * 0.55, y: floor - kidH + r * 1.35)
                ctx.fill(Path(ellipseIn: CGRect(x: cheek.x - 5, y: cheek.y - 3, width: 10, height: 6)), with: .color(Color.pink.opacity(0.45)))
                label("💋", cheek, .white, 8)
            }
        }
        var hx: CGFloat = 75
        var lean: Double = 0
        switch stage {
        case 0: hx = 420 - CGFloat(min(1, p)) * 345
        case 2:
            let k = min(2, Int(kissPhase)), f = kissPhase - Double(k)
            hx = xs[k] - 40
            if k > 0 && f < 0.25 { hx = xs[k - 1] - 40 + CGFloat(f / 0.25) * 75 }   // steps over to the next boy
            else if k == 0 && f < 0.25 { hx = 75 + CGFloat(f / 0.25) * (xs[0] - 40 - 75) }
            lean = f < 0.25 ? 0 : sin((f - 0.25) / 0.75 * .pi) * 0.42
            if f > 0.5 && f < 0.85 {
                let u = (f - 0.5) / 0.35
                label("❤️", CGPoint(x: xs[k] - 8 + CGFloat(u) * 10, y: floor - kidH - CGFloat(u) * 30), .white, 12)
            }
        case 3: hx = xs[2] - 40 + CGFloat(min(1, p * 1.5)) * 400
        default: break
        }
        var lc = ctx
        lc.translateBy(x: hx, y: floor); lc.rotate(by: .radians(lean)); lc.translateBy(x: -hx, y: -floor)
        drawPerson(&lc, look: Cast.hostess, feet: CGPoint(x: hx, y: floor), h: 116, mood: .happy,
                   arms: stage == 1 ? .hands : (stage == 3 ? .wave : .down), facing: 1)
        if stage == 3 {
            for k in 0..<3 {
                let u = (t * 0.7 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                label("♥", CGPoint(x: xs[k] - 5, y: floor - kidH - 6 - CGFloat(u) * 22), Color.pink.opacity(1 - u), 12)
            }
        }
    case .bossTantrum(let stage):
        drawArcade(&ctx, size)
        drawParkedZambonis(&ctx, floor: floor, t: t)
        if stage == 3 {
            // the boys snicker behind their hands, shaking with laughter
            for (i, x) in [70.0, 125, 180].enumerated() {
                let shake = CGFloat(abs(sin(t * 14 + Double(i)))) * 2.5
                drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: kidH, girl: 0, mood: .laughing, arms: .snicker, facing: 1, bob: -shake)
            }
            let tee = ["hee", "hee hee", "snrk", "ha ha"]
            for k in 0..<3 {
                let u = (t * 0.8 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                label(tee[(k + Int(t)) % tee.count], CGPoint(x: 70 + CGFloat(k) * 55 + 18, y: floor - 100 - CGFloat(u) * 25), Color.yellow.opacity(1 - u), 11)
            }
        } else {
            kids([70, 125, 180], girl: 0, mood: .surprised, arms: .hands, facing: 1)
        }
        // Mr. Grubb: jumping, shaking, red-faced, steaming
        let H: CGFloat = 130
        let jump = stage == 1 ? 0 : CGFloat(abs(sin(t * 9))) * 16
        let shake = CGFloat(sin(t * 47)) * 2.5
        let bx: CGFloat = 300 + shake
        let feetY = floor - jump
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: bx, y: feetY), h: H, mood: .angry, arms: stage == 2 ? .point : .up, facing: -1)
        let r = H * 0.095
        let head = CGPoint(x: bx, y: feetY - H + r)
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r, width: r * 2, height: r * 2)), with: .color(Color.red.opacity(0.4)))
        // steam from both ears
        for side in [-1.0, 1.0] {
            for k in 0..<4 {
                let u = (t * 1.6 + Double(k) / 4).truncatingRemainder(dividingBy: 1)
                let px = head.x + CGFloat(side) * (r * 1.1 + CGFloat(u) * 22)
                let py = head.y - CGFloat(u) * 34
                let pr = 3 + CGFloat(u) * 8
                ctx.fill(Path(ellipseIn: CGRect(x: px - pr, y: py - pr, width: pr * 2, height: pr * 2)), with: .color(.white.opacity(0.85 * (1 - u))))
            }
        }
        // stomp dust when he lands
        if stage != 1 && jump < 3 {
            for side in [-1.0, 1.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: bx + CGFloat(side) * 22 - 8, y: floor - 6, width: 16, height: 8)), with: .color(Color(white: 0.8, opacity: 0.7)))
            }
        }
        let curse = ["#@$%!", "!!!", "GRRR!", "&%#@!"]
        for k in 0..<3 {
            let a = t * 2 + Double(k) * 2.1
            label(curse[(k + Int(t * 2)) % curse.count], CGPoint(x: bx + CGFloat(cos(a)) * 48, y: head.y - 30 + CGFloat(sin(a)) * 12), .red, 13)
        }
        if stage == 1 { label("💢", CGPoint(x: head.x + r * 1.4, y: head.y - r * 1.2), .red, 20) }
    case .repoArrive:
        drawArcade(&ctx, size)
        drawParkedZambonis(&ctx, floor: floor, t: t)
        drawTruck(&ctx, at: CGPoint(x: 220 - CGFloat(1 - p) * 120, y: floor), label: "REPO")
        kids([60, 100, 140], girl: 0, mood: .surprised)
    case .repoAskKidsOut:
        drawArcade(&ctx, size)
        drawTruck(&ctx, at: CGPoint(x: 220, y: floor), label: "REPO")
        drawPerson(&ctx, look: Cast.repo1, feet: CGPoint(x: 190, y: floor), h: 120, arms: .point, facing: -1)
        kids([40 - CGFloat(p) * 30, 80 - CGFloat(p) * 30, 120 - CGFloat(p) * 30], girl: 0, mood: .surprised)
    case .repoAskGrubb(let who):
        drawArcade(&ctx, size)
        drawParkedZambonis(&ctx, floor: floor, t: t)
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 110, y: floor), h: 120, mood: who == 1 ? .angry : .surprised, arms: who == 1 ? .hands : .down, facing: 1)
        drawPerson(&ctx, look: Cast.repo1, feet: CGPoint(x: 260, y: floor), h: 122, mood: .neutral, arms: who == 0 ? .point : .hands, facing: -1)
        drawPerson(&ctx, look: Cast.repo2, feet: CGPoint(x: 320, y: floor), h: 118, mood: .neutral, arms: .carry, facing: -1)
        // the paperwork
        ctx.fill(Path(CGRect(x: 225, y: floor - 70, width: 16, height: 20)), with: .color(.white))
    case .repoArgue(let mood):
        drawArcade(&ctx, size, machines: 5)
        drawParkedZambonis(&ctx, floor: floor, t: t)
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 110, y: floor), h: 120, mood: mood, arms: mood == .angry ? .point : .hands, facing: 1, bob: mood == .angry ? b : 0)
        drawPerson(&ctx, look: Cast.repo1, feet: CGPoint(x: 260, y: floor), h: 122, mood: .neutral, arms: .hands, facing: -1)
        drawPerson(&ctx, look: Cast.repo2, feet: CGPoint(x: 320, y: floor), h: 118, mood: .neutral, arms: .carry, facing: -1)
        if mood == .angry { label("💢", CGPoint(x: 135, y: floor - 125), .red, 18) }
    case .repoFight:
        drawArcade(&ctx, size, machines: 4)
        drawPerson(&ctx, look: Cast.repo2, feet: CGPoint(x: 320, y: floor), h: 118, mood: .surprised, arms: .up, facing: -1)
        dust(&ctx, at: CGPoint(x: 200, y: floor - 60), r: 75, t: t)
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 160 + b * 4, y: floor), h: 120, mood: .angry, arms: .fight, facing: 1, bob: b)
        drawPerson(&ctx, look: Cast.repo1, feet: CGPoint(x: 245 - b * 3, y: floor), h: 122, mood: .angry, arms: .hands, facing: -1)
    case .repoZambonis:
        drawArcade(&ctx, size, machines: 6)
        let truckX: CGFloat = 250
        for (i, start) in [-60.0, 50, 160].enumerated() {
            let x = start + CGFloat(min(1, p * 1.2)) * (truckX + 40 - start) * CGFloat(0.6 + Double(i) * 0.2)
            if x < truckX + 30 {
                drawZamboni(&ctx, x: x, floor: floor, s: 0.6, driver: i == 0 ? Cast.repo2 : nil, driverH: 90, mood: .neutral, t: t)
            }
        }
        drawTruck(&ctx, at: CGPoint(x: truckX, y: floor), scale: 0.9, label: "REPO")
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 40, y: floor), h: 120, mood: .sad, arms: .up, facing: 1)
    case .powerCut(let stage):
        let on = stage < 2
        drawArcade(&ctx, size, machines: 0, lightsOn: on)
        drawBreakerBox(&ctx, at: CGPoint(x: 300, y: floor - 140), on: on)
        if stage == 0 {
            drawTruck(&ctx, at: CGPoint(x: 160 + CGFloat(1 - min(1, p)) * 260, y: floor), label: "POWER CO.", color: Color(red: 0.98, green: 0.85, blue: 0.2))
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 70, y: floor), h: 120, mood: .surprised, arms: .down, facing: 1)
        } else {
            drawPerson(&ctx, look: Cast.power, feet: CGPoint(x: 290, y: floor), h: 122, mood: .neutral, arms: .up, facing: 1)
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 130, y: floor), h: 120, mood: stage == 1 ? .angry : .sad, arms: stage == 1 ? .up : .down, facing: 1, bob: stage == 1 ? b : 0)
            if stage == 1 { label("💢", CGPoint(x: 152, y: floor - 125), .red, 18) }
        }
        if !on {
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.55)))
            label("CLUNK!", CGPoint(x: 317, y: floor - 158), .yellow, 14)
        }
    case .repoLoading(let n):
        drawArcade(&ctx, size, machines: max(0, 6 - n), lightsOn: n < 6)
        drawTruck(&ctx, at: CGPoint(x: 220, y: floor), label: "REPO", load: n)
        drawPerson(&ctx, look: Cast.repo1, feet: CGPoint(x: 200 + CGFloat(p) * 20, y: floor), h: 120, arms: .carry)
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 60, y: floor), h: 120, mood: .sad, arms: .down)
    case .foreclosure:
        drawArcade(&ctx, size, machines: 0, lightsOn: false)
        ctx.fill(Path(CGRect(x: 140, y: 70, width: 120, height: 40)), with: .color(.white))
        label("FORECLOSED", CGPoint(x: 200, y: 82), .red, 15)
        label("Property of Boardwalk Bank", CGPoint(x: 200, y: 100), .black, 8)
        drawPerson(&ctx, look: Cast.bank1, feet: CGPoint(x: 250, y: floor), h: 122, arms: .hands, facing: -1)
        drawPerson(&ctx, look: Cast.bank2, feet: CGPoint(x: 310, y: floor), h: 116, arms: .point, facing: -1)
        drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 110, y: floor), h: 120, mood: .sad)
        kids([30, 60, 90], girl: 0, mood: .surprised, h: 80)
    case .trikeRepo(let stage):
        drawBoardwalk(&ctx, size)
        let tx: CGFloat = stage == 0 ? 120 : 120 + CGFloat(p) * 300 + (stage == 2 ? 300 : 0)
        drawTruck(&ctx, at: CGPoint(x: tx + 60, y: floor), scale: 0.8, label: "REPO")
        drawTrike(&ctx, at: CGPoint(x: tx - 10, y: floor - 4), scale: 0.8)
        if stage == 0 {
            drawPerson(&ctx, look: Cast.repo2, feet: CGPoint(x: tx + 40, y: floor), h: 118, arms: .carry, facing: -1)
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 40, y: floor), h: 120, mood: .surprised, arms: .up)
        } else if stage == 1 {
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 30 + CGFloat(p) * 260, y: floor), h: 120, mood: .angry, arms: .up, facing: 1, bob: b * 3)
        } else {
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: 290 + CGFloat(p) * 200, y: floor), h: 120 * CGFloat(1 - p * 0.6), mood: .angry, arms: .up, facing: 1, bob: b * 3)
        }
    case .trikeLaugh(let stage):
        drawBoardwalk(&ctx, size)
        let xs: [CGFloat] = [150, 205, 260]
        if stage <= 1 {
            // doubled over, shaking with laughter
            for (i, x) in xs.enumerated() {
                let shake = CGFloat(abs(sin(t * 14 + Double(i)))) * 3
                drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: kidH, girl: 0, mood: .laughing, arms: .snicker, facing: stage == 1 ? -1 : 1, bob: -shake)
            }
            let ha = ["HA HA!", "ha ha ha", "HAHA!", "hee hee"]
            for k in 0..<3 {
                let u = (t * 0.8 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                label(ha[(k + Int(t)) % ha.count], CGPoint(x: xs[k] + 14, y: floor - kidH - 14 - CGFloat(u) * 28), Color.yellow.opacity(1 - u), 12)
            }
        } else {
            kids(xs, girl: 0, mood: stage == 2 ? .happy : .laughing, arms: stage == 2 ? .point : .snicker, facing: -1)
        }
        if stage >= 1 {
            // Grubb: walks back in panting, then stomps off the way he came
            let gx: CGFloat = stage == 1 ? -40 + CGFloat(min(1, p)) * 120 : stage == 2 ? 80 : 80 - CGFloat(p) * 160
            let mood: Mood = stage == 1 ? .tired : .angry
            drawPerson(&ctx, look: Cast.boss, feet: CGPoint(x: gx, y: floor), h: 120, mood: mood, arms: stage == 1 ? .down : .up,
                       facing: stage == 3 ? -1 : 1, bob: stage == 1 ? b * 2 : b * 3)
            if stage == 1 {
                // sweat drops + puffs of breath
                for k in 0..<3 {
                    let u = (t * 1.2 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                    label("💦", CGPoint(x: gx - 14 + CGFloat(k) * 14, y: floor - 128 + CGFloat(u) * 20), .white, 10)
                }
                label("huff… puff…", CGPoint(x: gx + 30, y: floor - 140), .white, 10)
            } else {
                label("💢", CGPoint(x: gx + 22, y: floor - 128), .red, 20)
            }
        }
    case .kidsOutOfWork:
        drawBoardwalk(&ctx, size)
        kids([150, 200, 250], girl: 0, mood: .sad)
    case .pierWalk:
        // the pier slides past as they walk out to its end
        drawPier(&ctx, size, offset: CGFloat(p) * 160, end: 460 - CGFloat(p) * 120)
        kids([110, 155, 200], girl: 0, mood: .neutral, facing: 1)
    case .pierEnd(let stage):
        drawPier(&ctx, size, offset: 160, end: 250)
        let wl = size.height * 0.74
        drawShip(&ctx, x: 232, waterline: wl, w: 300)
        // gangway from the end of the pier up to the ship's deck
        let gTop = CGPoint(x: 300, y: wl - 300 * 0.22 * 0.9)
        let gBot = CGPoint(x: 236, y: floor - 4)
        var gw = Path(); gw.move(to: gBot); gw.addLine(to: gTop)
        ctx.stroke(gw, with: .color(Color(white: 0.55)), lineWidth: 6)
        ctx.stroke(gw.offsetBy(dx: 0, dy: -12), with: .color(Color(white: 0.75)), lineWidth: 1.5)
        if stage == 0 {
            drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 232, y: floor), h: 120, mood: .happy, arms: .wave, facing: -1)
            kids([90, 135, 180], girl: 0, mood: .happy, facing: 1)
        } else {
            drawPerson(&ctx, look: Cast.hostess, feet: gTop, h: 100, mood: .happy, arms: .wave, facing: -1)
            for i in 0..<3 {
                // each boy walks to the gangway, then climbs it (front boy first)
                let start: CGFloat = 90 + CGFloat(i) * 45
                let u = max(0, min(1, p * 1.6 - Double(2 - i) * 0.3))
                let walk = min(1, u * 2), climb = max(0, u * 2 - 1)
                let x = start + CGFloat(walk) * (gBot.x - start) + CGFloat(climb) * (gTop.x - 20 - gBot.x)
                let y = floor + CGFloat(climb) * (gTop.y - floor)
                if climb < 0.98 {
                    drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: y), h: kidH * (1 - 0.15 * CGFloat(climb)), girl: 0, mood: .happy, facing: 1, bob: u > 0 && u < 1 ? b * 2 : 0)
                }
            }
        }
    case .portReturn:
        drawBoardwalk(&ctx, size, evening: true)
        drawShip(&ctx, x: 60, waterline: size.height * 0.58, w: 320, gangway: true)
        let dx = CGFloat(p) * 120
        kids([110 + dx, 155 + dx, 200 + dx], girl: 1, mood: .happy, facing: 1)
    case .shipWelcome, .notGirls:
        drawGameLounge(&ctx, size)
        label("✨ GAMES FOR GIRLS ✨", CGPoint(x: 200, y: 80), Color(red: 0.8, green: 0.1, blue: 0.5), 18)
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 90, y: floor), h: 122, mood: .happy, arms: kind.isNotGirls ? .point : .up, facing: 1)
        kids([220, 280, 340], girl: 0, mood: kind.isNotGirls ? .surprised : .neutral, arms: kind.isNotGirls ? .hands : .down, facing: -1)
    case .secretRoom:
        drawSecretRoom(&ctx, size, glow: t)
        for x in [120.0, 200, 280] { drawChair(&ctx, x: x, floor: floor, helmet: 0, beam: 0, t: t) }
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 40, y: floor), h: 122, mood: .happy, arms: .point, facing: 1)
        kids([340, 365, 390], girl: 0, mood: .surprised, h: 80, facing: -1)
    case .strapped, .transforming:
        drawSecretRoom(&ctx, size, glow: t)
        let morph: Double = kind.isTransforming ? p : 0
        let beam = kind.isTransforming ? 1.0 : 0
        for (i, x) in [120.0, 200, 280].enumerated() {
            drawChair(&ctx, x: x, floor: floor, helmet: beam > 0 ? 1 : p, beam: beam, t: t)
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: 84, girl: morph, mood: kind.isTransforming ? .surprised : .neutral, arms: .strapped)
        }
    case .mirror, .passengerMirror:
        drawSecretRoom(&ctx, size, glow: t)
        let mr = CGRect(x: 230, y: 40, width: 150, height: 170)
        drawMirror(&ctx, mr)
        let looks: [Look] = kind.isPassengerMirror ? sc.passengers.map(\.look) : Cast.kids
        let n = looks.count
        for (i, look) in looks.enumerated() {
            let x = 40 + CGFloat(i) * (170 / CGFloat(max(1, n)))
            drawPerson(&ctx, look: look, feet: CGPoint(x: x, y: floor), h: kidH, girl: 1, mood: .surprised, arms: .hands, facing: 1)
            // reflection
            var rctx = ctx
            rctx.clip(to: Path(roundedRect: mr, cornerRadius: 10))
            rctx.opacity = 0.85
            drawPerson(&rctx, look: look, feet: CGPoint(x: mr.minX + 22 + CGFloat(i) * (110 / CGFloat(max(1, n))), y: mr.maxY - 6), h: 120, girl: 1, mood: .happy, arms: .hands, facing: -1)
        }
    case .firstGame:
        drawGameLounge(&ctx, size)
        kids([130, 200, 270], girl: 1, mood: .happy, arms: .up)
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 360, y: floor), h: 122, mood: .happy, arms: .wave)
    case .acceptJob:
        drawGameLounge(&ctx, size)
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 90, y: floor), h: 122, mood: .happy, arms: .point, facing: 1)
        kids([220, 280, 340], girl: 1, mood: .happy, arms: .up)
    case .homeMom(let mood):
        drawLivingRoom(&ctx, size, night: true)
        drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 330, y: floor), h: 120, mood: mood, arms: mood == .surprised ? .up : .hands, facing: -1)
        kids([100, 160, 220], girl: 1, mood: .happy, facing: 1)
    case .homeTell(let who):
        drawLivingRoom(&ctx, size, night: true)
        drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 330, y: floor), h: 120, mood: .surprised, arms: .hands, facing: -1)
        for (i, x) in [100.0, 160, 220].enumerated() {
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: kidH, girl: 1, mood: .happy, arms: i == who ? .wave : .down, facing: 1, bob: 0)
        }
    case .morning(let day):
        drawLivingRoom(&ctx, size)
        label("Day \(day)", CGPoint(x: 200, y: 30), Color(red: 0.6, green: 0.2, blue: 0.4), 18)
        drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 330, y: floor), h: 120, mood: .happy, arms: .wave, facing: -1)
        kids([100, 160, 220], girl: 1, mood: .happy, facing: 1)
    case .vanity(let i):
        drawVanity(&ctx, size, girl: i, p: p, t: t)
    case .bedrooms(let asleep):
        drawGirlRooms(&ctx, size, cabins: false, asleep: asleep, p: p, t: t)
    case .cabins(let asleep):
        drawGirlRooms(&ctx, size, cabins: true, asleep: asleep, p: p, t: t)
    case .shipMorning(let day):
        drawGirlRooms(&ctx, size, cabins: true, asleep: false, p: 1, t: t, morning: true)
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 382, y: floor), h: 104, mood: .happy, arms: .wave, facing: -1)
        label("Day \(day)", CGPoint(x: 200, y: 16), .white, 14)
    case .boardingPassengers:
        drawBoardwalk(&ctx, size)
        drawShip(&ctx, x: 40, waterline: size.height * 0.58, w: 300, gangway: true)
        kids([200, 225, 250], girl: 1, mood: .happy, h: 70)
        for (i, ps) in sc.passengers.enumerated() {
            drawPerson(&ctx, look: ps.look, feet: CGPoint(x: 290 + CGFloat(i) * 28 - CGFloat(p) * 40, y: floor), h: 72, girl: 0, mood: .surprised, facing: -1)
        }
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 80, y: floor - 6), h: 100, mood: .happy, arms: .wave)
    case .passengerChairs(let tr):
        drawSecretRoom(&ctx, size, glow: t)
        let n = max(1, sc.passengers.count)
        for (i, ps) in sc.passengers.enumerated() {
            let x: CGFloat = n == 1 ? 200 : 70 + CGFloat(i) * (260 / CGFloat(n - 1))
            drawChair(&ctx, x: x, floor: floor, helmet: tr ? 1 : p, beam: tr ? 1 : 0, t: t)
            drawPerson(&ctx, look: ps.look, feet: CGPoint(x: x, y: floor), h: 84, girl: tr ? p : 0, mood: tr ? .surprised : .neutral, arms: .strapped)
        }
    case .sailing(let port, let home):
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.55, green: 0.82, blue: 1)))
        ctx.fill(Path(CGRect(x: 0, y: size.height * 0.58, width: size.width, height: size.height * 0.42)), with: .color(Color(red: 0.15, green: 0.5, blue: 0.8)))
        for k in 0..<9 {
            var wx = (Double(k) * 55 - t * 40).truncatingRemainder(dividingBy: 495)
            if wx < 0 { wx += 495 }
            label("~", CGPoint(x: CGFloat(wx) - 40, y: size.height * 0.74 + CGFloat(k % 3) * 16), .white.opacity(0.75), 20)
        }
        let sx = home ? 400 - CGFloat(p) * 330 : -190 + CGFloat(p) * 330
        drawShip(&ctx, x: sx, waterline: size.height * 0.66, w: 190)
        label(home ? "Next stop: the Boardwalk" : "Next stop: \(port.title)", CGPoint(x: 200, y: 18), Color(red: 0.6, green: 0.1, blue: 0.4), 14)
    case .atPort(let port):
        drawPort(&ctx, size, port, t: t)
        kids([150, 200, 250], girl: 1, mood: .happy, arms: .wave, h: 80)
        drawPerson(&ctx, look: Cast.hostess, feet: CGPoint(x: 330, y: floor), h: 100, mood: .happy, arms: .point, facing: -1)
    case .customs(let item, let seized):
        drawCustoms(&ctx, size, item: item, seized: seized, t: t)
    case .shipUpgraded:
        drawBoardwalk(&ctx, size)
        drawShip(&ctx, x: 50, waterline: size.height * 0.58, w: 300, gangway: true)
        for k in 0..<5 {
            let u = (t * 0.7 + Double(k) / 5).truncatingRemainder(dividingBy: 1)
            label("✨", CGPoint(x: 80 + CGFloat(k) * 60, y: 60 - CGFloat(u) * 30), .yellow.opacity(1 - u), 16)
        }
        kids([300, 330, 360], girl: 1, mood: .happy, arms: .up, h: 70)
    case .momGifts(let item):
        drawLivingRoom(&ctx, size, night: true)
        drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 330, y: floor), h: 120, mood: .happy, arms: item == nil ? .hands : .up, facing: -1)
        kids([100, 160, 220], girl: 1, mood: .happy, arms: item == nil ? .wave : .down, facing: 1)
        if let item {
            label(item, CGPoint(x: 290, y: floor - 140 + CGFloat(sin(t * 3)) * 4), .white, 34)
            label("🎁", CGPoint(x: 270, y: floor - 10), .white, 22)
        } else {
            label("🎁🎁🎁", CGPoint(x: 270, y: floor - 12), .white, 22)
        }
    case .bankDrive(let leg):
        drawBoardwalk(&ctx, size)
        if leg == 0 {
            drawBank(&ctx, size, outside: true)
            drawCar(&ctx, x: -150 + CGFloat(min(1, p * 1.1)) * 200, ground: floor + 4, driver: Cast.mom, driverMood: .happy, kids: true, kidGirl: 1)
        } else {
            drawShip(&ctx, x: 190, waterline: size.height * 0.58, w: 230, gangway: true)
            drawCar(&ctx, x: -150 + CGFloat(min(1, p * 1.1)) * 190, ground: floor + 4, driver: Cast.mom, driverMood: .happy, kids: true, kidGirl: 1)
        }
    case .bankLobby(let who):
        drawBank(&ctx, size, outside: false)
        drawPerson(&ctx, look: Cast.teller, feet: CGPoint(x: 330, y: floor - 46), h: 112, mood: .happy, arms: who >= 0 ? .hands : .wave, facing: -1)
        drawBankCounter(&ctx, size, floor: floor)
        if who >= 0 {
            label("💵", CGPoint(x: 284, y: floor - 70 + CGFloat(sin(t * 3)) * 3), .green, 20)
        }
        drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 50, y: floor), h: 120, mood: .happy, arms: .hands, facing: 1)
        for i in 0..<3 {
            let atWindow = i == who
            let x: CGFloat = atWindow ? 250 : 100 + CGFloat(i) * 42
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: kidH, girl: 1, mood: .happy, arms: atWindow ? .up : .down, facing: 1)
        }
    case .endOfDay:
        drawLivingRoom(&ctx, size, night: true)
        drawPerson(&ctx, look: Cast.mom, feet: CGPoint(x: 330, y: floor), h: 120, mood: .happy, arms: .up, facing: -1)
        kids([100, 160, 220], girl: 1, mood: .happy, arms: .up)
        label("💵", CGPoint(x: 280, y: 60), .green, 26)
    }
}

/// The three maintenance zambonis, parked in the back of the arcade.
func drawParkedZambonis(_ ctx: inout GraphicsContext, floor: CGFloat, t: Double) {
    for x in [40.0, 150, 260] {
        drawZamboni(&ctx, x: x, floor: floor - 26, s: 0.55, t: t, light: false)
    }
}

extension SceneKind {
    var isLunchBoss: Bool { if case .lunchBoss = self { return true }; return false }
    var isNotGirls: Bool { if case .notGirls = self { return true }; return false }
    var isTransforming: Bool { if case .transforming = self { return true }; return false }
    var isPassengerMirror: Bool { if case .passengerMirror = self { return true }; return false }
}
