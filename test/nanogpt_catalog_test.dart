import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/models/nanogpt_catalog.dart';

void main() {
  group('NanoGptModelInfo parsing', () {
    test('parses detailed catalog fields', () {
      final model = NanoGptModelInfo.fromCatalogMap({
        'id': 'meta-llama/Llama-3.3-70B-Instruct',
        'owned_by': 'meta',
        'name': 'Llama 3.3 70B Instruct',
        'context_length': 128000,
        'max_output_tokens': 8192,
        'category': 'General',
        'description': 'A strong open model',
        'subscription': {'included': true},
        'capabilities': {
          'vision': false,
          'reasoning': true,
          'tool_calling': true,
          'structured_output': true,
        },
        'pricing': {'prompt': 0.2, 'completion': 0.4},
      });

      expect(model.id, contains('Llama-3.3-70B'));
      expect(model.ownedBy, 'meta');
      expect(model.contextLength, 128000);
      expect(model.maxOutputTokens, 8192);
      expect(model.subscriptionIncluded, isTrue);
      expect(model.capabilities.reasoning, isTrue);
      expect(model.capabilities.toolCalling, isTrue);
      expect(model.parameterSizeLabel, '70B');
      expect(model.contextLabel, '128K ctx');
      expect(model.pricingLine, contains('Included'));
    });

    test('maps auto-model ids to Auto provider', () {
      final model = NanoGptModelInfo.fromCatalogMap({
        'id': 'auto-model-premium',
        'owned_by': 'nanogpt',
        'name': 'Auto Premium',
      });
      expect(model.ownedBy, NanoGptModelInfo.autoProviderLabel);
      expect(NanoGptModelInfo.isAutoModelId(model.id), isTrue);
    });
  });

  group('uncensored heuristic', () {
    test('matches category or name/id/description', () {
      final byCat = NanoGptModelInfo.fromCatalogMap({
        'id': 'x',
        'owned_by': 'y',
        'name': 'Normal',
        'category': 'Uncensored',
      });
      expect(byCat.isUncensoredFriendly, isTrue);

      final byName = NanoGptModelInfo.fromCatalogMap({
        'id': 'vendor/abliterated-7b',
        'owned_by': 'y',
        'name': 'Something',
      });
      expect(byName.isUncensoredFriendly, isTrue);

      final clean = NanoGptModelInfo.fromCatalogMap({
        'id': 'openai/gpt-4o',
        'owned_by': 'openai',
        'name': 'GPT-4o',
        'category': 'General',
      });
      expect(clean.isUncensoredFriendly, isFalse);
    });
  });

  group('filters', () {
    final models = [
      NanoGptModelInfo.fromCatalogMap({
        'id': 'auto-model',
        'owned_by': 'nanogpt',
        'name': 'Auto',
        'context_length': 128000,
        'category': 'General',
      }),
      NanoGptModelInfo.fromCatalogMap({
        'id': 'a/uncensored-chat',
        'owned_by': 'alpha',
        'name': 'Uncensored Chat',
        'context_length': 8000,
        'category': 'Uncensored',
      }),
      NanoGptModelInfo.fromCatalogMap({
        'id': 'b/tiny',
        'owned_by': 'beta',
        'name': 'Tiny',
        'context_length': 4000,
        'category': 'General',
      }),
    ];

    test('category filter includes broad uncensored bucket', () {
      final ids = NanoGptCatalogFilters.categoryFilterIds(models);
      expect(ids.first, NanoGptCatalogFilters.allCategoryId);
      expect(ids[1], NanoGptCatalogFilters.uncensoredFriendlyId);

      final broad = NanoGptCatalogFilters.applyCategory(
        models,
        NanoGptCatalogFilters.uncensoredFriendlyId,
      );
      expect(broad.map((m) => m.id), contains('a/uncensored-chat'));
    });

    test('context and provider filters compose', () {
      final filtered = NanoGptCatalogFilters.applyPipeline(
        models: models,
        categoryId: NanoGptCatalogFilters.allCategoryId,
        contextId: NanoGptCatalogFilters.context8kId,
        providerId: NanoGptCatalogFilters.allProviderId,
      );
      expect(filtered.length, 2);
      expect(filtered.every((m) => (m.contextLength ?? 0) >= 8000), isTrue);
    });

    test('Auto providers sort first', () {
      final providers = NanoGptCatalogFilters.providerFilterIds(models);
      expect(providers[0], NanoGptCatalogFilters.allProviderId);
      expect(providers[1], NanoGptModelInfo.autoProviderLabel);
    });
  });

  group('runtime stats', () {
    test('parses providers payload', () {
      final stats = NanoGptModelRuntimeStats.fromProvidersMap({
        'autoTps': 42.5,
        'autoTtftMs': 320,
        'providers': [
          {'available': true},
          {'available': true},
          {'available': false},
        ],
      });
      expect(stats.tps, 42.5);
      expect(stats.ttftMs, 320);
      expect(stats.uptimePercent, 67);
      expect(stats.tpsLabel, contains('TPS'));
    });
  });
}
