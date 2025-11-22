import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'about_page.dart';
import 'product_details_page.dart';
import 'design_tokens.dart';

Future<void> _launchEmail(String email, {String subject = ''}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: subject.isNotEmpty ? {'subject': subject} : null,
  );
  if (!await launchUrl(uri)) {
    // ignore: use_build_context_synchronously
    // couldn't launch mail app - show snackbar via context when available
  }
}

/// Reusable standardized AppBar for all pages with consistent navigation
PreferredSizeWidget buildAppBar(
  BuildContext context, {
  required String title,
  bool showTitle = true,
  bool isHome = false,
  bool isStore = false,
}) {
  return AppBar(
    backgroundColor: AppTokens.colorBlack,
    title: showTitle
        ? ShinyText(
            text: title,
            speed: 3,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTokens.colorLightGrey,
            ),
          )
        : null,
    actions: [
      TextButton(
        onPressed: isHome
            ? null
            : () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              },
        child: Text('Home', style: AppTokens.labelLarge),
      ),
      TextButton(
        onPressed: isStore
            ? null
            : () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const StorePage()),
                  (route) => false,
                );
              },
        child: Text('Store', style: AppTokens.labelLarge),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SupportChatPage()),
          );
        },
        child: Text('Support', style: AppTokens.labelLarge),
      ),
      TextButton(
        onPressed: () {
          _launchEmail('support@company.com', subject: 'Support request');
        },
        child: Text('Contact', style: AppTokens.labelLarge),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AboutPage()),
          );
        },
        child: Text('About', style: AppTokens.labelLarge),
      ),
      cartNavButton(context),
    ],
  );
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTokens.appTheme,
        home: const HomePage(),
      ),
    ),
  );
}

// Support Chat page — user messages appear on the right (black bubble),
// support messages appear on the left (orange bubble). The input area is
// orange and the send control is an orange circular send icon.
class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Each message is usually a map {'text': String, 'isUser': bool} but
  // on web or after a hot-reload the stored state may appear as a
  // List<String>. Use a dynamic list and defensively handle both shapes.
  final List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    // welcome message from support
    _messages.add({'text': 'Hi — how can we help you today?', 'isUser': false});
    // slight delay to let the list render before scrolling to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _ctrl.clear();
    });
    _scrollToBottom();

    // fake support reply for demo
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text':
              'Thanks for your message — a support agent will reply shortly.',
          'isUser': false
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // delay slightly to allow ListView to update sizes
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, title: 'Support'),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('No messages yet — send us a question',
                        style: AppTokens.bodyMedium.copyWith(
                            color:
                                AppTokens.colorWhite.withValues(alpha: 0.7))),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingSm,
                        vertical: AppTokens.spacingMd),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final item = _messages[i];

                      // normalize item to text + isUser
                      String text;
                      bool isUser;
                      if (item is Map) {
                        text = (item['text'] ?? '').toString();
                        isUser = item['isUser'] == true;
                      } else {
                        // fallback: treat plain strings as user messages
                        text = item?.toString() ?? '';
                        isUser = true;
                      }

                      final bubbleColor =
                          isUser ? AppTokens.colorBlack : AppTokens.colorOrange;

                      // align right for user, left for support
                      return Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppTokens.spacingSm,
                                    vertical: AppTokens.spacingXs),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                        isUser ? AppTokens.radiusMd : 4),
                                    topRight: Radius.circular(
                                        isUser ? 4 : AppTokens.radiusMd),
                                    bottomLeft:
                                        Radius.circular(AppTokens.radiusMd),
                                    bottomRight:
                                        Radius.circular(AppTokens.radiusMd),
                                  ),
                                ),
                                child: Text(text,
                                    style: AppTokens.bodyMedium
                                        .copyWith(color: AppTokens.colorWhite)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input area — orange background text field and circular send icon
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingSm,
                  vertical: AppTokens.spacingXs),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTokens.colorOrange,
                        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: AppTokens.spacingSm),
                      child: TextField(
                        controller: _ctrl,
                        style: AppTokens.bodyMedium
                            .copyWith(color: AppTokens.colorWhite),
                        cursorColor: AppTokens.colorWhite,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: AppTokens.bodyMedium.copyWith(
                              color:
                                  AppTokens.colorWhite.withValues(alpha: 0.7)),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTokens.spacingXs),
                  // larger tappable send 'blobb' — uses InkWell to ensure
                  // taps are registered across platforms (web included)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTokens.colorOrange,
                      shape: BoxShape.circle,
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (_ctrl.text.trim().isEmpty) return;
                        _sendMessage();
                      },
                      child: Center(
                        child: Icon(Icons.send, color: AppTokens.colorWhite),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Product model for featured carousel
class FeaturedProduct {
  final String name;
  final String description;
  final String price;
  final IconData icon;

  FeaturedProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
  });
}

// Featured Products Carousel
class FeaturedProductsCarousel extends StatefulWidget {
  const FeaturedProductsCarousel({super.key});

  @override
  State<FeaturedProductsCarousel> createState() =>
      _FeaturedProductsCarouselState();
}

class _FeaturedProductsCarouselState extends State<FeaturedProductsCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<FeaturedProduct> featuredProducts = [
    FeaturedProduct(
      name: 'Most Bought Product',
      description:
          'RoboArm X1 - Precision robotic arm with adaptive AI control.',
      price: '₱24,999',
      icon: Icons.precision_manufacturing,
    ),
    FeaturedProduct(
      name: 'Most Popular Product',
      description:
          'DroneEye 360 - Autonomous drone with panoramic navigation sensors.',
      price: '₱49,999',
      icon: Icons.flight,
    ),
    FeaturedProduct(
      name: 'Recommended Product',
      description:
          'AutoBot Z - Self-learning mobile assistant robot for industrial use.',
      price: '₱149,999',
      icon: Icons.smart_toy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      final nextPage = (_currentIndex + 1) % featuredProducts.length;
      _pageController.animateToPage(
        nextPage,
        duration: AppTokens.transitionSlow,
        curve: Curves.easeInOut,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppTokens.spacingXl),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            'Featured Selection',
            style: AppTokens.headingMedium,
          ),
        ),
        SizedBox(height: AppTokens.spacingMd),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: featuredProducts.length,
            itemBuilder: (context, index) {
              final product = featuredProducts[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingSm),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTokens.colorWhite,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppTokens.colorBlack.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(AppTokens.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color:
                                  AppTokens.colorOrange.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusMd),
                            ),
                            child: Icon(
                              product.icon,
                              size: 36,
                              color: AppTokens.colorOrange,
                            ),
                          ),
                          SizedBox(height: AppTokens.spacingSm),
                          Text(
                            product.name,
                            style: AppTokens.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppTokens.spacingXs),
                          Text(
                            product.description,
                            style: AppTokens.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.price,
                            style: AppTokens.priceTag,
                          ),
                          SizedBox(height: AppTokens.spacingSm),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.colorOrange,
                                foregroundColor: AppTokens.colorWhite,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppTokens.spacingSm,
                                ),
                              ),
                              onPressed: () {
                                // Navigate to product details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} selected'),
                                  ),
                                );
                              },
                              child: Text(
                                'View Product',
                                style: AppTokens.labelLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: AppTokens.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            featuredProducts.length,
            (index) => AnimatedContainer(
              duration: AppTokens.transitionFast,
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? AppTokens.colorOrange
                    : AppTokens.colorLightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: AppTokens.spacingXl),
      ],
    );
  }
}

// StoreMenuButton with hover dropdown animation

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, title: 'COMPANY NAME', isHome: true),
      body: LayoutBuilder(builder: (context, constraints) {
        final height = MediaQuery.of(context).size.height - kToolbarHeight;
        // Stack: fixed hero at top, scrollable content beneath it
        return Stack(
          children: [
            // Fixed hero banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                height: height,
                padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
                color: AppTokens.colorOrange,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSplitText(
                      text: 'Discover the Future of Robotics',
                      style: AppTokens.headingLarge,
                    ),
                    SizedBox(height: AppTokens.spacingSm),
                    // This TextType stays fixed at the top now
                    TextType(
                      text: [
                        'AI-powered machines designed to revolutionize everyday life.'
                      ],
                      typingSpeed: 40,
                      pauseDuration: 1800,
                      textStyle: AppTokens.bodyLarge,
                    ),
                    SizedBox(height: AppTokens.spacingLg),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.colorWhite,
                          padding: EdgeInsets.symmetric(
                              horizontal: AppTokens.spacingLg,
                              vertical: AppTokens.spacingMd),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusXl))),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StorePage()));
                      },
                      child: Text('Explore Our Products',
                          style: GoogleFonts.poppins(
                              color: AppTokens.colorOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content below the fixed hero
            Positioned.fill(
              top: height,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppTokens.spacingXl),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
                      child: Text('Featured Products',
                          style: AppTokens.headingMedium),
                    ),
                    SizedBox(height: AppTokens.spacingSm),
                    SizedBox(height: 260, child: const FutureProductCarousel()),
                    SizedBox(height: AppTokens.spacingLg),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StorePage()));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTokens.colorOrange),
                        child: Text('View All Products',
                            style: AppTokens.labelLarge),
                      ),
                    ),
                    SizedBox(height: AppTokens.spacing2xl),
                    // CTA
                    Container(
                      width: double.infinity,
                      color: AppTokens.colorDarkGrey,
                      padding: EdgeInsets.symmetric(
                          vertical: AppTokens.spacingXl,
                          horizontal: AppTokens.spacingLg),
                      child: Column(
                        children: [
                          Text('Join the Future of Robotics',
                              style: AppTokens.headingSmall),
                          SizedBox(height: AppTokens.spacingXs),
                          Text(
                              'Collaborate, invest, or explore our latest breakthroughs in AI automation.',
                              style: AppTokens.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class FutureProductCarousel extends StatefulWidget {
  const FutureProductCarousel({super.key});

  @override
  State<FutureProductCarousel> createState() => _FutureProductCarouselState();
}

class _FutureProductCarouselState extends State<FutureProductCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int _index = 0;

  final List<Map<String, String>> featuredProducts = [
    {
      'name': 'RoboArm X1',
      'desc': 'Precision robotic arm with adaptive AI control.',
      'price': '₱24,999'
    },
    {
      'name': 'DroneEye 360',
      'desc': 'Autonomous drone with panoramic navigation sensors.',
      'price': '₱49,999'
    },
    {
      'name': 'AutoBot Z',
      'desc': 'Self-learning mobile assistant robot for industrial use.',
      'price': '₱149,999'
    },
  ];

  @override
  void initState() {
    super.initState();
    // simple auto-scroll
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    _index = (_index + 1) % featuredProducts.length;
    _controller.animateToPage(_index,
        duration: AppTokens.transitionSlow, curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: featuredProducts.length,
            onPageChanged: (idx) => setState(() => _index = idx),
            itemBuilder: (context, i) {
              final p = featuredProducts[i];
              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingSm,
                    vertical: AppTokens.spacingXs),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTokens.colorOrange,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: AppTokens.colorOrange),
                  ),
                  padding: EdgeInsets.all(AppTokens.spacingMd),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy,
                          size: 52, color: AppTokens.colorWhite),
                      SizedBox(height: AppTokens.spacingSm),
                      Text(p['name']!, style: AppTokens.headingSmall),
                      SizedBox(height: AppTokens.spacingXs),
                      Text(p['desc']!,
                          textAlign: TextAlign.center,
                          style: AppTokens.bodyLarge),
                      SizedBox(height: AppTokens.spacingSm),
                      Text(p['price']!, style: AppTokens.priceTag),
                      SizedBox(height: AppTokens.spacingSm),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.colorWhite,
                          foregroundColor: AppTokens.colorOrange,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(
                                productIndex: i,
                                productName: p['name']!,
                                productDesc: p['desc']!,
                                productPrice: p['price']!,
                              ),
                            ),
                          );
                        },
                        child:
                            Text('View Product', style: AppTokens.labelLarge),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: AppTokens.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featuredProducts.length, (i) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: _index == i ? 14 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _index == i
                    ? AppTokens.colorOrange
                    : AppTokens.colorLightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// StoreMenuButton with hover dropdown animation
class StoreMenuButton extends StatefulWidget {
  const StoreMenuButton({super.key});

  @override
  State<StoreMenuButton> createState() => _StoreMenuButtonState();
}

class _StoreMenuButtonState extends State<StoreMenuButton> {
  OverlayEntry? _dropdownOverlay;
  final LayerLink _layerLink = LayerLink();

  final List<String> componentTypes = [
    'Insert type of component here 1',
    'Insert type of component here 2',
    'Insert type of component here 3',
    'Insert type of component here 4',
    'Insert type of component here 5',
  ];

  void _showDropdown() {
    if (_dropdownOverlay != null) return;
    _dropdownOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 180,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFED5833),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(componentTypes.length, (index) {
                    return ListTile(
                      title: Text(
                        componentTypes[index],
                        style: const TextStyle(color: Color(0xFFE3EEF1)),
                      ),
                      onTap: () {
                        // Add navigation or action here
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_dropdownOverlay!);
  }

  void _hideDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showDropdown(),
        onExit: (_) => _hideDropdown(),
        child: TextButton(
          onPressed: () {},
          child: const Text('Store', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class AnimatedSplitText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration delay;
  final Duration duration;

  const AnimatedSplitText({
    super.key,
    required this.text,
    required this.style,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedSplitText> createState() => _AnimatedSplitTextState();
}

class _AnimatedSplitTextState extends State<AnimatedSplitText>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _opacities;
  late final List<Animation<Offset>> _offsets;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.text.length, (i) {
      return AnimationController(vsync: this, duration: widget.duration);
    });
    _opacities = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _offsets = _controllers
        .map((c) => Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _run();
  }

  Future<void> _run() async {
    for (final c in _controllers) {
      await Future.delayed(widget.delay);
      if (!mounted) return;
      c.forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: List.generate(widget.text.length, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return Opacity(
              opacity: _opacities[i].value,
              child: Transform.translate(
                offset: _offsets[i].value * 10,
                child: Text(widget.text[i], style: widget.style),
              ),
            );
          },
        );
      }),
    );
  }
}

// Cart Model
// Typing animation used in StorePage and elsewhere
class TextType extends StatefulWidget {
  final List<String> text;
  final int typingSpeed; // ms per character
  final int pauseDuration; // ms between texts
  final bool showCursor;
  final String cursorCharacter;
  final TextStyle? textStyle;

  const TextType({
    super.key,
    required this.text,
    this.typingSpeed = 75,
    this.pauseDuration = 1500,
    this.showCursor = true,
    this.cursorCharacter = '|',
    this.textStyle,
  });

  @override
  State<TextType> createState() => _TextTypeState();
}

class _TextTypeState extends State<TextType> {
  int _textIndex = 0;
  int _charIndex = 0;
  String _displayed = '';
  bool _typing = true;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  Future<void> _startTyping() async {
    if (widget.text.isEmpty) return;
    while (mounted) {
      final current = widget.text[_textIndex % widget.text.length];
      while (_charIndex < current.length) {
        await Future.delayed(Duration(milliseconds: widget.typingSpeed));
        if (!mounted) return;
        setState(() {
          _charIndex++;
          _displayed = current.substring(0, _charIndex);
        });
      }
      // finished one word
      await Future.delayed(Duration(milliseconds: widget.pauseDuration));
      if (!mounted) return;
      setState(() {
        _textIndex = (_textIndex + 1) % widget.text.length;
        _charIndex = 0;
        _displayed = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.showCursor
          ? '$_displayed${_typing ? widget.cursorCharacter : ''}'
          : _displayed,
      style: widget.textStyle ??
          GoogleFonts.poppins(
              fontSize: 18,
              color: const Color(0xFFED5833),
              fontWeight: FontWeight.w600),
    );
  }
}

class CartModel extends ChangeNotifier {
  final List<int> _cartItems = [];
  List<int> get cartItems => _cartItems;

  void addToCart(int index) {
    _cartItems.add(index);
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.remove(index);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}

// Cart Page Widget
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Offset _buttonOffset = const Offset(100, 100);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    return Scaffold(
      appBar: buildAppBar(context, title: 'Your Cart'),
      body: Listener(
        onPointerHover: (event) {
          setState(() {
            _buttonOffset = event.localPosition;
          });
        },
        child: Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.all(AppTokens.spacingLg),
              itemCount: cart.cartItems.length,
              itemBuilder: (context, i) {
                final idx = cart.cartItems[i];
                return Card(
                  child: ListTile(
                    title: Text('Product ${idx + 1}'),
                    subtitle: const Text(
                        'Short description of the product goes here.'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_shopping_cart),
                      onPressed: () => cart.removeFromCart(idx),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: _buttonOffset.dx,
              top: _buttonOffset.dy,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.colorOrange,
                  foregroundColor: AppTokens.colorWhite,
                ),
                onPressed: cart.cartItems.isEmpty
                    ? null
                    : () {
                        cart.clearCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase successful!')),
                        );
                      },
                child: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Update navigation bars in HomePage, StorePage, SupportChatPage to include Cart icon:
Widget cartNavButton(BuildContext context) {
  final cart = Provider.of<CartModel>(context);
  return Stack(
    children: [
      IconButton(
        icon: Icon(Icons.shopping_cart, color: AppTokens.colorWhite),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
        },
      ),
      if (cart.cartItems.isNotEmpty)
        Positioned(
          right: 0,
          child: Container(
            padding: EdgeInsets.all(AppTokens.spacing2xs),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${cart.cartItems.length}',
              style: TextStyle(color: AppTokens.colorLightGrey, fontSize: 12),
            ),
          ),
        ),
    ],
  );
}

// Example for StorePage (repeat for other pages):
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          buildAppBar(context, title: 'STORE - COMPANY NAME', isStore: true),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: false,
            backgroundColor: AppTokens.colorDarkGrey,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              title: Container(
                color: AppTokens.colorDarkGrey,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: AppTokens.spacingXs),
                    TextType(
                      text: [
                        "What are you interested in?",
                        "have a look around",
                        "Happy Shopping",
                        "Sales are open soon!"
                      ],
                      typingSpeed: 75,
                      pauseDuration: 1500,
                      showCursor: true,
                      cursorCharacter: "|",
                      textStyle: AppTokens.headingSmall.copyWith(
                        color: AppTokens.colorOrange,
                      ),
                    ),
                    SizedBox(height: AppTokens.spacingSm),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(AppTokens.spacingLg),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimatedProductCard(
                      index: index, delay: Duration.zero);
                },
                childCount: 30,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Header delegate used for the pinned animated banner in StorePage

// Add this widget below _ProductCard:
class AnimatedProductCard extends StatefulWidget {
  final int index;
  final Duration delay;
  const AnimatedProductCard(
      {super.key, required this.index, required this.delay});

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTokens.transitionFast,
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Start immediately (no staggered per-item delay) to keep fade duration
    // consistent across product widgets per QA requirements.
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: PixelTransitionCard(index: widget.index),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final int index;
  const _ProductCard({required this.index});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: AppTokens.transitionFast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTokens.colorLightGrey,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppTokens.colorOrange.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTokens.colorBlack.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: _hovering
              ? Border.all(color: AppTokens.colorOrange, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        margin: EdgeInsets.all(AppTokens.spacing2xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 48, color: AppTokens.colorOrange),
            SizedBox(height: AppTokens.spacingSm),
            Text(
              'Product ${widget.index + 1}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTokens.colorBlack,
              ),
            ),
            SizedBox(height: AppTokens.spacingXs),
            Text(
              'Short description of the product goes here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(color: AppTokens.colorBlack),
            ),
            SizedBox(height: AppTokens.spacingXs),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsPage(
                      productIndex: widget.index,
                      productName: 'Product ${widget.index + 1}',
                      productDesc:
                          'Short description of the product goes here.',
                      productPrice: '₱9,999',
                    ),
                  ),
                );
              },
              child: Text('View Product', style: GoogleFonts.openSans()),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this widget above your pages:
class ShinyText extends StatefulWidget {
  final String text;
  final double speed;
  final TextStyle? style;
  final bool disabled;

  const ShinyText({
    super.key,
    required this.text,
    this.speed = 3,
    this.style,
    this.disabled = false,
  });

  @override
  State<ShinyText> createState() => _ShinyTextState();
}

class _ShinyTextState extends State<ShinyText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppTokens.transitionSlow)
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disabled) {
      return Text(widget.text, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                AppTokens.colorLightGrey,
                AppTokens.colorOrange,
                AppTokens.colorLightGrey
              ],
              stops: [
                (_controller.value - 0.2).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.2).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style ??
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        );
      },
    );
  }
}

class PixelTransitionCard extends StatefulWidget {
  final int index;
  const PixelTransitionCard({super.key, required this.index});

  @override
  State<PixelTransitionCard> createState() => _PixelTransitionCardState();
}

class _PixelTransitionCardState extends State<PixelTransitionCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  // Replaced tiled pixel animation with a simple fade overlay.
  // _hovering controls showing the overlay via AnimatedOpacity.
  late final AnimationController _bounceController;
  late final Animation<double> _scale;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: AppTokens.transitionNormal,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
    _startBounceLoop();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _startBounceLoop() async {
    while (mounted) {
      final seconds = 2 + _random.nextInt(7); // 2..8s
      await Future.delayed(Duration(seconds: seconds));
      if (!mounted) break;
      try {
        await _bounceController.forward();
        await _bounceController.reverse();
      } catch (_) {
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
      },
      onExit: (_) {
        setState(() => _hovering = false);
      },
      child: AnimatedContainer(
        duration: AppTokens.transitionSlow,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hovering
                ? [AppTokens.colorOrange, AppTokens.colorTeal]
                : [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: AppTokens.colorOrange.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTokens.colorBlack.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: _hovering
              ? Border.all(color: AppTokens.colorOrange, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        margin: EdgeInsets.all(AppTokens.spacing2xs),
        child: Stack(
          children: [
            // Card content
            AnimatedOpacity(
              opacity: _hovering ? 0.0 : 1.0,
              duration: AppTokens.transitionFast,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy,
                        size: 48, color: AppTokens.colorOrange),
                    SizedBox(height: AppTokens.spacingSm),
                    Text('Product ${widget.index + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTokens.colorBlack)),
                    SizedBox(height: AppTokens.spacingXs),
                    Text('Short description of the product goes here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTokens.colorBlack)),
                    SizedBox(height: AppTokens.spacingXs),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(
                              productIndex: widget.index,
                              productName: 'Product ${widget.index + 1}',
                              productDesc:
                                  'Short description of the product goes here.',
                              productPrice: '₱9,999',
                            ),
                          ),
                        );
                      },
                      child: const Text('View Product'),
                    ),
                  ],
                ),
              ),
            ),
            // Simple fade overlay replacing tiled pixel animation
            if (_hovering)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _hovering ? 1.0 : 0.0,
                  duration: AppTokens.transitionFast,
                  child: Container(
                    alignment: Alignment.center,
                    color: AppTokens.colorOrange.withValues(alpha: 0.88),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Lorem Ipsum",
                          style: AppTokens.headingSmall.copyWith(
                            color: AppTokens.colorLightGrey,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: AppTokens.spacingSm),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTokens.colorWhite),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsPage(
                                  productIndex: widget.index,
                                  productName: 'Product ${widget.index + 1}',
                                  productDesc:
                                      'Short description of the product goes here.',
                                  productPrice: '₱9,999',
                                ),
                              ),
                            );
                          },
                          child: Text('View Product',
                              style: GoogleFonts.poppins(
                                  color: AppTokens.colorOrange,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Bouncing View Product pill
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: ScaleTransition(
                scale: _scale,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(
                            productIndex: widget.index,
                            productName: 'Product ${widget.index + 1}',
                            productDesc:
                                'Short description of the product goes here.',
                            productPrice: '₱9,999',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingLg,
                          vertical: AppTokens.spacingXs),
                      decoration: BoxDecoration(
                        color: AppTokens.colorOrange,
                        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.colorBlack.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text('View Product',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTokens.colorWhite)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
