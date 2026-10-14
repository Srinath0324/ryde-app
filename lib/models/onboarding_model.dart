class OnboardingModel {
  final String title;
  final String description;
  final String imagePath;

  OnboardingModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  static List<OnboardingModel> getOnboardingData() {
    return [
      OnboardingModel(
        title: 'The best car in your hands with Ryde',
        description:
            'Discover the convenience of finding your perfect ride with our Ryde App',
        imagePath: 'assets/onborading 1.png',
      ),
      OnboardingModel(
        title: 'The perfect ride is just a tap away!',
        description:
            'Your journey begins with Ryde. Find your ideal ride effortlessly.',
        imagePath: 'assets/onborading 2.png',
      ),
      OnboardingModel(
        title: 'Your ride, your way. Let\'s get started!',
        description:
            'Enter your destination, sit back, and let us take care of the rest.',
        imagePath: 'assets/onborading 3.png',
      ),
      OnboardingModel(
        title: 'Let\'s get started',
        description: 'Sign up or log in to find out the best car for you',
        imagePath: 'assets/IMG.png',
      ),
    ];
  }
}
