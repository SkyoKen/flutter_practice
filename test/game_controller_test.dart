import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/models/game_controller.dart';

Future<DateTime> _advanceManualToTicket(
  GameController game,
  DateTime now,
) async {
  var cursor = now;
  for (var index = 0; index < 10 && game.customerOrderFoodId == null; index++) {
    cursor = cursor.add(const Duration(seconds: 1));
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 1),
      now: cursor,
    );
  }
  return cursor;
}

Future<DateTime> _advanceManualUntilDone(
  GameController game,
  DateTime now,
) async {
  var cursor = now;
  for (var index = 0;
      index < 80 && game.manualDiningCustomer != null;
      index++) {
    cursor = cursor.add(const Duration(seconds: 1));
    await game.simulateBusinessTick(
      const [],
      elapsed: const Duration(seconds: 1),
      now: cursor,
    );
  }
  return cursor;
}

void main() {
  group('GameController', () {
    test('starts with default idle restaurant values', () async {
      final game = GameController(storage: MemoryGameStorage());
      final now = DateTime(2026, 1, 1, 12);

      await game.load(now: now);

      expect(game.coins, GameController.startingCoins);
      expect(game.lifetimeEarnings, 0);
      expect(game.restaurantLevel, 1);
      expect(game.seatLevel, 1);
      expect(game.serviceLevel, 1);
      expect(game.kitchenLevel, 1);
      expect(game.restaurantXp, 0);
      expect(game.bestCombo, 0);
      expect(game.shiftOrdersServed, 0);
      expect(game.shiftMissedOrders, 0);
      expect(game.unlockedFoodIds, containsAll([1, 2, 3, 4, 5]));
      expect(game.isFoodUnlocked(9), isFalse);
      expect(game.businessLoadRatio, 0);
      expect(game.kitchenLoadRatio, 0);
      expect(game.checkoutLoadRatio, 0);
      expect(game.businessEatingCount, 0);
      expect(game.hasBusinessActivity, isFalse);
      expect(game.pendingOfflineEarnings, 0);
    });

    test('business display ratios reflect loaded automatic dining state',
        () async {
      final game = GameController(
        storage: MemoryGameStorage({
          'idle_business_queue_count': 2,
          'idle_seat_level': 2,
          'idle_business_seated_count': 3,
          'idle_business_kitchen_queue': 1,
          'idle_business_eating_count': 1,
          'idle_business_checkout_queue': 1,
          'idle_pending_business_earnings': 12.0,
        }),
      );

      await game.load(now: DateTime(2026, 1, 1, 12));

      expect(game.businessLoadRatio, 1);
      expect(game.businessEatingCount, 1);
      expect(game.kitchenLoadRatio, closeTo(1 / 3, 0.001));
      expect(game.checkoutLoadRatio, closeTo(1 / 3, 0.001));
      expect(game.hasBusinessActivity, isTrue);
    });

    test('calculates offline earnings for 30 minutes', () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.save();

      final resumed = GameController(storage: storage);
      await resumed.load(now: start.add(const Duration(minutes: 30)));

      expect(
        resumed.pendingOfflineEarnings,
        resumed.revenuePerMinute * 30,
      );
    });

    test('caps offline earnings at 8 hours', () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.save();

      final resumed = GameController(storage: storage);
      await resumed.load(now: start.add(const Duration(hours: 12)));

      expect(
        resumed.pendingOfflineEarnings,
        resumed.revenuePerMinute * GameController.maxOfflineMinutes,
      );
    });

    test('upgrades deduct coins and improve revenue', () async {
      final game = GameController(storage: MemoryGameStorage());
      await game.load(now: DateTime(2026, 1, 1, 12));
      final revenueBefore = game.revenuePerMinute;

      final upgraded = await game.upgradeSeats();

      expect(upgraded, isTrue);
      expect(game.coins, GameController.startingCoins - 100);
      expect(game.seatLevel, 2);
      expect(game.revenuePerMinute, greaterThan(revenueBefore));
    });

    test('upgrade fails when coins are insufficient', () async {
      final game = GameController(storage: MemoryGameStorage());
      await game.load(now: DateTime(2026, 1, 1, 12));

      expect(await game.upgradeMenuItem(1), isTrue);
      final coinsAfterFirstUpgrade = game.coins;

      expect(await game.upgradeMenuItem(1), isFalse);
      expect(game.menuLevel(1), 1);
      expect(game.coins, coinsAfterFirstUpgrade);
    });

    test('claiming offline earnings adds coins and lifetime earnings',
        () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.save();

      final resumed = GameController(storage: storage);
      await resumed.load(now: start.add(const Duration(minutes: 10)));
      final pending = resumed.pendingOfflineEarnings;

      await resumed.claimOfflineEarnings(
        now: start.add(const Duration(minutes: 10)),
      );

      expect(resumed.pendingOfflineEarnings, 0);
      expect(resumed.coins, GameController.startingCoins + pending);
      expect(resumed.lifetimeEarnings, pending);
    });

    test('automatic business tick serves customers into pending income',
        () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      final completed = await game.simulateBusinessTick(
        [1, 2, 3],
        elapsed: const Duration(minutes: 3),
        now: start.add(const Duration(minutes: 3)),
      );

      expect(completed, greaterThan(0));
      expect(game.customerOrdersServed, completed);
      expect(game.pendingBusinessEarnings, greaterThan(0));
      expect(game.coins, GameController.startingCoins);
      expect(game.dailyOrdersServed, completed);

      final pending = game.pendingBusinessEarnings;
      await game.claimOfflineEarnings(
        now: start.add(const Duration(minutes: 4)),
      );

      expect(game.pendingBusinessEarnings, 0);
      expect(game.coins, GameController.startingCoins + pending);
      expect(game.lifetimeEarnings, pending);
    });

    test('automatic business creates real visible activity quickly', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      await game.simulateBusinessTick(
        [1, 2, 3],
        elapsed: const Duration(seconds: 6),
        now: start.add(const Duration(seconds: 6)),
      );

      expect(
        game.businessQueueCount +
            game.businessSeatedCount +
            game.businessKitchenQueueCount +
            game.businessEatingCount +
            game.businessCheckoutQueueCount,
        greaterThan(0),
      );
    });

    test('automatic business waits through cook eat pay stages', () async {
      final storage = MemoryGameStorage({
        'idle_business_seated_count': 2,
        'idle_business_kitchen_queue': 1,
      });
      final game = GameController(storage: storage);
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      await game.simulateBusinessTick(
        const [],
        elapsed: const Duration(seconds: 7),
        now: start.add(const Duration(seconds: 7)),
      );

      expect(game.businessKitchenQueueCount, 1);
      expect(
        game.diningCustomers.any(
          (customer) => customer.phase == GameDiningCustomerPhase.servingFood,
        ),
        isTrue,
      );
      expect(game.businessEatingCount, 0);
      expect(game.businessCheckoutQueueCount, 0);
      expect(game.customerOrdersServed, 0);

      await game.simulateBusinessTick(
        const [],
        elapsed: const Duration(seconds: 3),
        now: start.add(const Duration(seconds: 10)),
      );

      expect(game.businessKitchenQueueCount, 0);
      expect(game.businessEatingCount, 1);
      expect(game.businessCheckoutQueueCount, 0);

      await game.simulateBusinessTick(
        const [],
        elapsed: Duration(
          seconds: game.businessMealDuration.inSeconds + 1,
        ),
        now: start
            .add(Duration(seconds: 11 + game.businessMealDuration.inSeconds)),
      );

      expect(game.businessEatingCount, 0);
      expect(game.businessCheckoutQueueCount, 1);
      expect(game.customerOrdersServed, 0);

      final completed = await game.simulateBusinessTick(
        const [],
        elapsed: const Duration(seconds: 10),
        now: start
            .add(Duration(seconds: 21 + game.businessMealDuration.inSeconds)),
      );

      expect(completed, 1);
      expect(game.customerOrdersServed, 1);
      expect(game.pendingBusinessEarnings, greaterThan(0));
    });

    test('orders add a small reward once per cooldown', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      final firstReward = await game.rewardOrder('100.00', now: start);
      expect(firstReward, GameController.manualOrderRewardCoins);
      expect(
        game.coins,
        GameController.startingCoins + GameController.manualOrderRewardCoins,
      );
      expect(game.lifetimeEarnings, GameController.manualOrderRewardCoins);

      final cooldownReward = await game.rewardOrder(
        '100.00',
        now: start.add(const Duration(seconds: 10)),
      );
      expect(cooldownReward, 0);
      expect(
        game.coins,
        GameController.startingCoins + GameController.manualOrderRewardCoins,
      );
      expect(
        game.orderRewardCooldownRemaining(
          start.add(const Duration(seconds: 10)),
        ),
        const Duration(seconds: 20),
      );

      final nextReward = await game.rewardOrder(
        '100.00',
        now: start.add(GameController.manualOrderRewardCooldown),
      );
      expect(nextReward, GameController.manualOrderRewardCoins);
      expect(
        game.coins,
        GameController.startingCoins +
            GameController.manualOrderRewardCoins * 2,
      );
      expect(
        game.lifetimeEarnings,
        GameController.manualOrderRewardCoins * 2,
      );
    });

    test('order reward cooldown survives reloads', () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.rewardOrder('100.00', now: start);

      final resumed = GameController(storage: storage);
      await resumed.load(now: start.add(const Duration(seconds: 15)));

      expect(
        resumed.orderRewardCooldownRemaining(
          start.add(const Duration(seconds: 15)),
        ),
        const Duration(seconds: 15),
      );
      expect(
        await resumed.rewardOrder(
          '100.00',
          now: start.add(const Duration(seconds: 15)),
        ),
        0,
      );
    });

    test('customer orders can be generated and served', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      expect(
        await game.ensureCustomerOrder([3, 1, 2], now: start),
        isTrue,
      );
      expect(game.manualDiningCustomer?.phase, GameDiningCustomerPhase.seating);
      expect(game.customerOrderFoodId, isNull);

      var now = await _advanceManualToTicket(game, start);
      expect(game.customerOrderFoodId, 1);
      final firstReward = game.customerOrderReward;
      expect(firstReward, game.customerOrderRewardForFood(1));

      final servedReward = await game.serveCustomerOrder(
        [3, 1, 2],
        now: now,
      );

      expect(servedReward, firstReward);
      expect(game.coins, GameController.startingCoins);
      expect(game.customerOrdersServed, 0);
      now = await _advanceManualUntilDone(game, now);
      expect(game.coins, GameController.startingCoins + firstReward);
      expect(game.lifetimeEarnings, firstReward);
      expect(game.customerOrdersServed, 1);
      expect(game.customerOrderFoodId, isNull);
      expect(game.nextCustomerAvailableAt, now.add(game.customerArrivalDelay));
      expect(
        await game.ensureCustomerOrder(
          [3, 1, 2],
          now: now.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(game.customerOrderFoodId, isNull);

      final secondStart = game.nextCustomerAvailableAt!;
      expect(
          await game.ensureCustomerOrder([3, 1, 2], now: secondStart), isTrue);
      await _advanceManualToTicket(game, secondStart);
      expect(game.customerOrderFoodId, 2);
    });

    test('customer service can pay a combo multiplier bonus', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);
      await game.ensureCustomerOrder([1], now: start);
      var now = await _advanceManualToTicket(game, start);
      final baseReward = game.customerOrderReward;

      final servedReward = await game.serveCustomerOrder(
        [1],
        now: now,
        rewardMultiplier: 1.5,
      );

      expect(servedReward, baseReward * 1.5);
      expect(game.coins, GameController.startingCoins);
      now = await _advanceManualUntilDone(game, now);
      expect(game.coins, GameController.startingCoins + servedReward);
      expect(game.lifetimeEarnings, servedReward);
    });

    test('best combo records highest combo and unlocks combo goal', () async {
      final storage = MemoryGameStorage();
      final game = GameController(storage: storage);
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);
      await game.ensureCustomerOrder([1], now: start);
      var now = await _advanceManualToTicket(game, start);

      await game.serveCustomerOrder(
        [1],
        now: now,
        combo: 3,
      );
      now = await _advanceManualUntilDone(game, now);

      expect(game.bestCombo, 3);
      final comboGoal = game.milestones.firstWhere(
        (milestone) => milestone.id == 'combo_three',
      );
      expect(comboGoal.claimable, isTrue);

      final nextOrderAt = game.nextCustomerAvailableAt!;
      await game.ensureCustomerOrder([1], now: nextOrderAt);
      now = await _advanceManualToTicket(game, nextOrderAt);
      await game.serveCustomerOrder(
        [1],
        now: now,
        combo: 2,
      );
      now = await _advanceManualUntilDone(game, now);

      expect(game.bestCombo, 3);

      final resumed = GameController(storage: storage);
      await resumed.load(now: now);

      expect(resumed.bestCombo, 3);
      expect(
        resumed.milestones
            .firstWhere((milestone) => milestone.id == 'combo_three')
            .claimable,
        isTrue,
      );
    });

    test('served dishes gain mastery and improve future rewards', () async {
      final storage = MemoryGameStorage();
      final game = GameController(storage: storage);
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);
      final rewardBeforeMastery = game.customerOrderRewardForFood(1);
      var now = start;

      for (var i = 0; i < GameController.menuMasteryXpPerLevel; i += 1) {
        expect(await game.ensureCustomerOrder([1], now: now), isTrue);
        now = await _advanceManualToTicket(game, now);
        expect(game.customerOrderFoodId, 1);
        await game.serveCustomerOrder(
          [1],
          now: now,
        );
        now = await _advanceManualUntilDone(game, now);
        now = game.nextCustomerAvailableAt!;
      }

      expect(game.servedCountForFood(1), GameController.menuMasteryXpPerLevel);
      expect(game.masteryXpForFood(1), GameController.menuMasteryXpPerLevel);
      expect(game.masteryLevelForFood(1), 1);
      expect(game.masteryProgressForFood(1), 0);
      expect(
        game.customerOrderRewardForFood(1),
        rewardBeforeMastery + 2,
      );

      final resumed = GameController(storage: storage);
      await resumed.load(now: now);

      expect(resumed.masteryXpForFood(1), game.masteryXpForFood(1));
      expect(resumed.servedCountForFood(1), game.servedCountForFood(1));
      expect(resumed.masteryLevelForFood(1), 1);
    });

    test('customer patience expires and missed orders pay nothing', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);
      await game.ensureCustomerOrder([1], now: start);
      final ticketAt = await _advanceManualToTicket(game, start);

      expect(
        game.customerPatienceRemaining(ticketAt),
        game.customerPatienceDuration,
      );
      expect(game.customerPatienceRatio(ticketAt), 1);

      final expiredAt = ticketAt.add(game.customerPatienceDuration);
      expect(game.customerOrderExpired(expiredAt), isTrue);
      expect(
        await game.serveCustomerOrder(
          [1],
          now: expiredAt,
          rewardMultiplier: 2,
        ),
        0,
      );
      expect(game.coins, GameController.startingCoins);
      expect(game.customerOrdersServed, 0);
      expect(game.customerOrderFoodId, isNull);
      expect(game.nextCustomerAvailableAt, isNotNull);
    });

    test('customer order survives reloads', () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.ensureCustomerOrder([7, 4], now: start);
      final ticketAt = await _advanceManualToTicket(firstSession, start);

      final resumed = GameController(storage: storage);
      await resumed.load(now: ticketAt.add(const Duration(seconds: 2)));

      expect(resumed.customerOrderFoodId, 4);
      expect(resumed.customerOrderReward, firstSession.customerOrderReward);
      expect(resumed.customerOrderCreatedAt, ticketAt);
    });

    test('next customer arrival wait survives reloads', () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.ensureCustomerOrder([1, 2], now: start);
      var now = await _advanceManualToTicket(firstSession, start);
      await firstSession.serveCustomerOrder(
        [1, 2],
        now: now,
      );
      now = await _advanceManualUntilDone(firstSession, now);

      final resumed = GameController(storage: storage);
      await resumed.load(now: now.add(const Duration(seconds: 1)));

      expect(resumed.customerOrderFoodId, isNull);
      expect(resumed.nextCustomerAvailableAt,
          firstSession.nextCustomerAvailableAt);
      expect(
        resumed.customerArrivalRemaining(now.add(const Duration(seconds: 1))),
        firstSession.customerArrivalDelay - const Duration(seconds: 1),
      );
      expect(
        await resumed.ensureCustomerOrder(
          [1, 2],
          now: now.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('milestones become claimable and cannot be claimed twice', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      expect(game.claimableMilestoneCount, 0);

      await game.ensureCustomerOrder([1], now: start);
      var now = await _advanceManualToTicket(game, start);
      final customerReward = await game.serveCustomerOrder(
        [1],
        now: now,
      );
      now = await _advanceManualUntilDone(game, now);

      expect(game.claimableMilestoneCount, 1);
      final firstService = game.milestones.first;
      expect(firstService.id, 'first_service');
      expect(firstService.claimable, isTrue);

      final milestoneReward = await game.claimMilestone(
        firstService.id,
        now: now,
      );

      expect(milestoneReward, 40);
      expect(
        game.coins,
        GameController.startingCoins + customerReward + milestoneReward,
      );
      expect(game.claimedMilestoneIds, contains(firstService.id));
      expect(await game.claimMilestone(firstService.id), 0);
    });

    test('claimed milestones survive reloads', () async {
      final storage = MemoryGameStorage();
      final start = DateTime(2026, 1, 1, 12);
      final firstSession = GameController(storage: storage);
      await firstSession.load(now: start);
      await firstSession.ensureCustomerOrder([1], now: start);
      var now = await _advanceManualToTicket(firstSession, start);
      await firstSession.serveCustomerOrder(
        [1],
        now: now,
      );
      now = await _advanceManualUntilDone(firstSession, now);
      await firstSession.claimMilestone(
        'first_service',
        now: now,
      );

      final resumed = GameController(storage: storage);
      await resumed.load(now: now.add(const Duration(minutes: 1)));

      expect(resumed.claimedMilestoneIds, contains('first_service'));
      expect(resumed.milestones.first.claimed, isTrue);
      expect(resumed.claimableMilestoneCount, 0);
    });

    test('shift summary records served, misses, combo, and coins', () async {
      final game = GameController(storage: MemoryGameStorage());
      var now = DateTime(2026, 1, 1, 12);
      await game.load(now: now);
      await game.startShift(now: now);
      await game.recordWrongDish(now: now);

      var earned = 0.0;
      for (var combo = 1; combo <= GameController.shiftTargetOrders; combo++) {
        expect(await game.ensureCustomerOrder([1], now: now), isTrue);
        now = await _advanceManualToTicket(game, now);
        earned += await game.serveCustomerOrder(
          [1],
          now: now,
          combo: combo,
        );
        now = await _advanceManualUntilDone(game, now);
        now = game.nextCustomerAvailableAt!;
      }

      expect(game.shiftReadyToFinish, isTrue);
      expect(game.shiftOrdersServed, GameController.shiftTargetOrders);
      expect(game.shiftMissedOrders, 1);
      expect(game.shiftBestCombo, GameController.shiftTargetOrders);
      expect(game.shiftCoinsEarned, earned);

      final summary = await game.finishShift(now: now);

      expect(summary.ordersServed, GameController.shiftTargetOrders);
      expect(summary.missedOrders, 1);
      expect(summary.bestCombo, GameController.shiftTargetOrders);
      expect(summary.coinsEarned, earned);
      expect(game.shiftOrdersServed, 0);
      expect(game.shiftMissedOrders, 0);
      expect(game.shiftCoinsEarned, 0);
    });

    test('locked foods stay out of customer pool until shop level unlocks',
        () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);

      expect(game.isFoodUnlocked(9), isFalse);
      expect(await game.ensureCustomerOrder([9], now: start), isFalse);

      await game.addRestaurantXp(400, now: start);

      expect(game.restaurantLevel, 5);
      expect(game.isFoodUnlocked(9), isTrue);
      expect(await game.ensureCustomerOrder([9], now: start), isTrue);
      await _advanceManualToTicket(game, start);
      expect(game.customerOrderFoodId, 9);
    });

    test('kitchen upgrade raises customer reward and daily upgrade progress',
        () async {
      final game = GameController(storage: MemoryGameStorage());
      await game.load(now: DateTime(2026, 1, 1, 12));
      final rewardBefore = game.customerOrderRewardForFood(1);

      expect(await game.upgradeKitchen(), isTrue);

      expect(game.kitchenLevel, 2);
      expect(game.customerOrderRewardForFood(1), greaterThan(rewardBefore));
      expect(game.dailyUpgrades, 1);
    });

    test('customer type changes patience and reward', () async {
      final game = GameController(storage: MemoryGameStorage());
      final start = DateTime(2026, 1, 1, 12);
      await game.load(now: start);
      await game.addRestaurantXp(100, now: start);

      expect(game.generateCustomerType(), GameCustomerType.impatient);
      expect(await game.ensureCustomerOrder([1], now: start), isTrue);
      await _advanceManualToTicket(game, start);

      expect(game.activeCustomerType, GameCustomerType.impatient);
      expect(
        game.customerPatienceDuration.inSeconds,
        lessThan(GameController.customerPatienceBaseSeconds),
      );
      expect(
        game.customerOrderReward,
        closeTo(game.customerOrderRewardForFood(1) * 1.16, 0.001),
      );
    });

    test('positive events can change arrival pace and rewards', () async {
      final game = GameController(storage: MemoryGameStorage());
      var now = DateTime(2026, 1, 1, 12);
      await game.load(now: now);

      for (var i = 0; i < 4; i += 1) {
        expect(await game.ensureCustomerOrder([1], now: now), isTrue);
        now = await _advanceManualToTicket(game, now);
        await game.serveCustomerOrder(
          [1],
          now: now,
        );
        now = await _advanceManualUntilDone(game, now);
        now = game.nextCustomerAvailableAt!;
      }

      expect(game.activeEventType, GameEventType.lunchRush);
      expect(
        game.customerArrivalDelay.inSeconds,
        lessThan(GameController.customerArrivalBaseSeconds),
      );
      expect(await game.ensureCustomerOrder([1], now: now), isTrue);
      await _advanceManualToTicket(game, now);
      expect(
        game.customerOrderReward,
        closeTo(
          game.customerOrderRewardForFood(1) * game.activeEventRewardMultiplier,
          0.001,
        ),
      );
    });

    test('daily tasks can be claimed once and reset on a new day', () async {
      final storage = MemoryGameStorage();
      final game = GameController(storage: storage);
      var now = DateTime(2026, 1, 1, 12);
      await game.load(now: now);

      for (var i = 0; i < 3; i += 1) {
        expect(await game.ensureCustomerOrder([1], now: now), isTrue);
        now = await _advanceManualToTicket(game, now);
        await game.serveCustomerOrder(
          [1],
          now: now,
          combo: i + 1,
        );
        now = await _advanceManualUntilDone(game, now);
        now = game.nextCustomerAvailableAt!;
      }

      final serviceTask = game.dailyTasks.firstWhere(
        (task) => task.id == 'daily_service_three',
      );
      expect(serviceTask.claimable, isTrue);

      final reward = await game.claimDailyTask(serviceTask.id, now: now);

      expect(reward, 90);
      expect(game.claimedDailyTaskIds, contains(serviceTask.id));
      expect(await game.claimDailyTask(serviceTask.id, now: now), 0);

      final resumedNextDay = GameController(storage: storage);
      await resumedNextDay.load(now: now.add(const Duration(days: 1)));

      expect(resumedNextDay.dailyOrdersServed, 0);
      expect(resumedNextDay.claimedDailyTaskIds, isEmpty);
    });
  });
}
