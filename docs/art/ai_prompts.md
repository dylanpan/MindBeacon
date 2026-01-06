# AI绘画Prompt生成

## 核心风格描述Prompt

### 主要Prompt (适用于Midjourney/DALL-E/Stable Diffusion)

```
Modern digital illustration, soft gradient style, warm orange-yellow color palette, muted saturation (0.1-0.2), high brightness (0.8-0.9), smooth color transitions, flat design elements, contemporary minimalist art, soft lighting, warm and inviting atmosphere, digital gradient techniques, subtle color variations, professional digital art style, 4721 unique colors, seamless color blending, modern illustration techniques
```

### 中文版本

```
现代数字插画，柔和渐变风格，暖橙黄色调色板，低饱和度（0.1-0.2），高亮度（0.8-0.9），平滑色彩过渡，扁平设计元素，当代简约艺术，柔和光照，温暖宜人氛围，数字渐变技术，精美色彩变化，专业数字艺术风格，丰富色彩层次，无缝色彩混合，现代插画技法
```

## 详细风格要素

### 色彩要素
```
Primary colors: warm orange-yellow (49.7° hue), 
Saturation: low (0.122), 
Brightness: high (0.870), 
Color palette: 4721 unique colors, 
Color distribution: 15.2% high saturation accents, 81.2% soft muted tones
```

### 技法要素
```
Gradient techniques: smooth seamless transitions, 
Edge characteristics: soft edges, low edge density (0.090), 
Texture: refined and smooth, 
Complexity: moderate (variance 4064.59), 
Digital art techniques: gradient tools, precise color mixing, soft filters
```

### 风格关键词
```
Modern Digital Illustration, 
Soft Gradient Art, 
Warm Color Palette, 
Muted Saturation, 
High Brightness, 
Contemporary Minimalist, 
Professional Digital Art, 
Smooth Color Transitions, 
Flat Design Elements, 
Warm and Inviting, 
Digital Gradient Techniques, 
Subtle Color Variations
```

## 分层Prompt结构

### 基础描述层
```
[主题描述] in modern digital illustration style
```

### 风格描述层
```
with soft gradient effects, warm orange-yellow dominant color palette (49.7° hue), muted saturation around 0.1-0.2, high brightness approximately 0.8-0.9
```

### 技法描述层
```
using smooth color transitions, low edge density (0.090), refined texture with 4721 unique color variations, contemporary minimalist approach
```

### 情感描述层
```
creating warm and inviting atmosphere, professional digital art quality, soft and friendly aesthetic
```

## 负面Prompt (避免不需要的元素)

```
avoid harsh contrasts, avoid high saturation colors, avoid dark tones, avoid sharp edges, avoid complex textures, avoid overly detailed elements, avoid cold color schemes, avoid strong shadows, avoid digital noise, avoid oversaturated areas
```

## 适配不同AI平台的Prompt

### Midjourney Prompt
```
Modern digital illustration, soft gradient style, warm orange-yellow palette, muted saturation, high brightness, smooth transitions, flat design, contemporary minimalist --style contemporary --v 6
```

### Stable Diffusion Prompt
```
modern digital illustration, soft gradient style, warm orange-yellow color palette, low saturation, high brightness, smooth color transitions, flat design elements, contemporary minimalist art, professional quality, (warm lighting), (soft edges)
Negative: harsh contrasts, high saturation, dark tones, sharp edges, complex textures
```

### DALL-E Prompt
```
Modern digital illustration with soft gradient effects, featuring a warm orange-yellow color palette with muted saturation and high brightness, smooth color transitions, flat design elements, contemporary minimalist style, creating warm and inviting atmosphere
```

## 使用建议

### 参数调节建议
- **Steps**: 30-50 (高质量)
- **CFG Scale**: 7-12
- **Sampling method**: DPM++ 2M Karras 或 Euler A
- **分辨率**: 1024x1024 或更高

### 风格强度控制
- **强烈风格**: 增加风格关键词权重
- **微妙风格**: 减少风格关键词，使用更多基础描述
- **个性化调整**: 根据具体需求调整色彩倾向
