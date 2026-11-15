import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class CarouselPage extends StatefulWidget {
  const CarouselPage({super.key});

  @override
  State<CarouselPage> createState() => _CarouselPageState();
}

class _CarouselPageState extends State<CarouselPage> {
  final AdwCarouselController _carouselController = AdwCarouselController();

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: AdwClamp(
        maximumSize: 740,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                child: AdwCarousel(
                  controller: _carouselController,
                  showNavigationButtons: true,
                  children: [
                    _buildBannerCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF632CA6), Color(0xFF813D9C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: const AdwEmblem(size: 64),
                      title: 'Emblema',
                      subtitle: 'Generar avatares de proyectos',
                    ),
                    _buildBannerCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A5FB4), Color(0xFF3584E4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: const Icon(
                        AdwIcons.applications_games_symbolic,
                        size: 64,
                        color: Color(0xFFFFFFFF),
                      ),
                      title: 'Retro Games',
                      subtitle: 'Colección de clásicos arcade y aventuras',
                    ),
                    _buildBannerCard(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF26A269), Color(0xFF33D17A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: const Icon(
                        AdwIcons.utilities_terminal_symbolic,
                        size: 64,
                        color: Color(0xFFFFFFFF),
                      ),
                      title: 'Code Builder',
                      subtitle: 'Herramientas modernas para desarrolladores',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: AdwCarouselIndicatorDots(
                controller: _carouselController,
                dotSize: 7,
                activeDotWidth: 20,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'CATEGORIES',
              style: theme.typography.sectionTitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategoryCard(
                    'Crear', const Color(0xFF7852FF), const Color(0xFF3B82F6)),
                _buildCategoryCard('Trabajo', const Color(0xFFF59E0B),
                    const Color(0xFFFBBF24)),
                _buildCategoryCard('Juegos', const Color(0xFFEC4899),
                    const Color(0xFF8B5CF6)),
                _buildCategoryCard('Socializar', const Color(0xFFEF4444),
                    const Color(0xFFF97316)),
                _buildCategoryCard('Aprendizaje', const Color(0xFF10B981),
                    const Color(0xFF059669)),
                _buildCategoryCard('Desarrollo', const Color(0xFF374151),
                    const Color(0xFF1F2937)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard({
    required Gradient gradient,
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              inherit: false,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 13,
              inherit: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String label, Color startColor, Color endColor) {
    return Container(
      width: 170,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AdwMetrics.buttonRadius),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            inherit: false,
          ),
        ),
      ),
    );
  }
}

